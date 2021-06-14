
import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

const int _BlockSize = 1024 * 1024 * 2;

class Range {
  int start;
  int end;

  Range(this.start, this.end);
}

class DownloadTask {
  int index;
  MultiDownloader downloader;
  File file;
  int loaded = 0;
  StreamSubscription<List<int>> _subscription;

  DownloadTask(this.index, this.downloader) {
    file = File("${downloader._tempDir.path}/$index");
  }

  Range get range => Range(index * _BlockSize, min((index + 1) * _BlockSize, downloader.totalLength));

  VoidCallback onComplete;
  void Function(String) onFailed;
  void Function(int loaded, int total) onProgress;

  void stop() {
    _subscription.cancel();
  }

  void start() async {
    http.Request request = http.Request("GET", downloader.uri);
    if (downloader.headers != null) {
      request.headers.addAll(downloader.headers);
    }
    request.headers["range"] = "bytes=${range.start}-${range.end - 1}";
    try {
      loaded = 0;
      var response = await request.send();

      if (response.statusCode >= 200 && response.statusCode < 300) {
        BytesBuilder builder = BytesBuilder();
        int contentLength = response.contentLength;
        Completer completer = Completer();
        _subscription = response.stream.listen((buffer) {
          builder.add(buffer);
          loaded += buffer.length;
          onProgress?.call(loaded, contentLength);
        }, onError: (Object error) {
          completer.completeError(error);
        }, onDone: () {
          completer.complete();
        }, cancelOnError: true);
        await completer.future;

        Directory parent = file.parent;
        if (!await parent.exists()) {
          await parent.create(recursive: true);
        }
        var buffer = builder.toBytes();
        if (buffer.length == 0) {
          onFailed?.call("Response body is empty.");
        } else {
          await file.writeAsBytes(buffer);
          onComplete?.call();
        }
      } else {
        onFailed?.call("Status code ${response.statusCode}");
      }
    } catch (e) {
      onFailed?.call(e.toString());
    }
  }
}

class MultiDownloader {
  final Uri uri;
  final Map<String, String> headers;
  final File file;
  final int maxThreading;

  int _blockCount;
  int totalLength;
  int loadedLength;
  String _eTag;
  bool _parting = false;
  Directory _tempDir;

  VoidCallback onComplete;
  void Function(String) onFailed;
  void Function(int loaded, int total) onProgress;

  Queue<DownloadTask> _queue;
  Set<DownloadTask> _downloading = Set();
  Future<void> _ready;

  Future<void> get ready => _ready;

  String _lastError;
  int _failedCount = 0;

  bool isComplete = false;
  bool isDownloading = false;

  MultiDownloader({
    @required this.uri,
    @required this.file,
    this.maxThreading = 5,
    this.headers}) {
    _ready = prepare();
  }

  Future<void> prepare() async {
    if (await file.exists()) {
      isComplete = true;
      return;
    }
    _tempDir = Directory("${file.path}.tmp");
    if (!await _tempDir.exists()) {
      await _tempDir.create(recursive: true);
    }

    loadedLength = 0;
    File indexFile = File("${_tempDir.path}/index");
    if (await indexFile.exists()) {
      try {
        Map<String, dynamic> map = jsonDecode(await indexFile.readAsString());
        totalLength = map["total"];
        _eTag = map["eTag"];

        await _freshQueue();
      } catch (e) {
      }
    }
  }

  Future<void> _freshQueue() async {
    _blockCount = (totalLength / _BlockSize).ceil();
    _queue = Queue();
    for (int i = 0; i < _blockCount; ++i) {
      File file = File("${_tempDir.path}/$i");
      var stat = await file.stat();
      if (stat.type == FileSystemEntityType.notFound) {
        _queue.add(DownloadTask(i, this));
      } else if (stat.type == FileSystemEntityType.file) {
        loadedLength += stat.size;
      }
    }
  }

  void start() async {
    if (isDownloading) return;
    isDownloading = true;
    await _ready;

    http.Request request = http.Request("HEAD", uri);
    if (this.headers != null) request.headers.addAll(this.headers);
    var response = await request.send();

    String eTag = response.headers["etag"];
    String acceptRages = response.headers["accept-ranges"];
    _parting = acceptRages == "bytes";
    if (_eTag == null || _eTag != eTag) {
      _eTag = eTag;
      totalLength = response.contentLength;

      if (await _tempDir.exists() || !_parting) {
        await _tempDir.delete(recursive: true);
        await _tempDir.create(recursive: true);
      }

      File indexFile = File("${_tempDir.path}/index");
      Map<String, dynamic> json = {
        "total": totalLength,
        "eTag": _eTag
      };
      await indexFile.writeAsString(jsonEncode(json));

      if (_parting)
        await _freshQueue();
    }

    if (_parting) {
      multiDownload();
    } else {
      directDownload();
    }
  }

  void stop() {
    if (!isDownloading) return;
    isDownloading = false;
    for (var task in _downloading) {
      task.stop();
      _queue.addFirst(task);
    }
    _downloading.clear();
  }

  void directDownload() async {
    http.Request request = http.Request("GET", uri);
    if (headers != null) {
      request.headers.addAll(headers);
    }
    try {
      var response = await request.send();

      if (response.statusCode >= 200 && response.statusCode < 300) {
        BytesBuilder builder = BytesBuilder();
        int contentLength = response.contentLength;
        await for (var buffer in response.stream) {
          builder.add(buffer);
          onProgress?.call(builder.length, contentLength);
        }

        Directory parent = file.parent;
        if (!await parent.exists()) {
          await parent.create(recursive: true);
        }
        await file.writeAsBytes(builder.toBytes());
        isDownloading = false;
        onComplete?.call();
      } else {
        isDownloading = false;
        onFailed?.call("Status code ${response.statusCode}");
      }
    } catch (e) {
      isDownloading = false;
      onFailed?.call(e.toString());
    }
  }

  void multiDownload() {
    _checkDownload();
  }

  void _checkDownload() {
    while ((_downloading.length + _failedCount) < maxThreading && _queue.length > 0) {
      var task = _queue.removeFirst();
      _downloading.add(task);
      task.onComplete = () async {
        _downloading.remove(task);
        if (_queue.length == 0) {
          if (_downloading.length == 0) {
            if (await _testComplete()) {
              isDownloading = false;
              onComplete?.call();
            } else {
              // test failed restart
              await _freshQueue();
              start();
            }
            return;
          }
        } else {
          _failedCount = 0;
          _checkDownload();
        }
        var stat = await task.file.stat();
        loadedLength += stat.size;
        onProgress?.call(loadedLength, totalLength);
      };
      task.onFailed = (String failed) {
        _lastError = failed;
        ++_failedCount;
        if (_failedCount > 5) {
          onFailed?.call(_lastError);
        } else {
          _queue.add(task);
          _checkDownload();
        }
      };
      task.onProgress = (loaded, total) {
        int loading = 0;
        for (var task in _downloading) {
          loading += task.loaded;
        }
        onProgress?.call(loadedLength + loading, totalLength);
      };
      task.start();
    }
  }

  Future<bool> _testComplete() async {
    var output = file.openWrite();
    for (int i = 0; i < _blockCount; ++i) {
      File file = File("${_tempDir.path}/$i");
      var exist = await file.exists();
      if (!exist) {
        output.close();
        return false;
      } else {
        await output.addStream(file.openRead());
      }
    }
    output.close();
    return true;
  }
}