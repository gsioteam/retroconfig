
import 'dart:async';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'package:convert/convert.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../configs.dart';
import 'multi_downloader.dart';
import 'package:path_provider/path_provider.dart' as path_provider;
import 'package:path/path.dart' as path;
import 'package:downloader_manager/downloader_manager.dart';

enum DownloadStatus {
  None,
  Downloading,
  Complete,
}

class DownloadItem {

  DownloadStatus _status;
  DownloadStatus get status => _status;
  File file;
  Downloader _downloader;

  VoidCallback onStatus;
  void Function(int, int) onProgress;
  Timer _timer;

  String key;

  DownloadItem._(this.key) {
    file = File("${Configs().romsRoot.path}/$key");
    if (file.existsSync()) {
      _status = DownloadStatus.Complete;
    } else {
      if (!file.parent.existsSync()) {
        file.parent.createSync(recursive: true);
      }
      for (var sub in file.parent.listSync(recursive: false)) {
        if (sub is File) {
          if (path.basenameWithoutExtension(sub.path) == path.basenameWithoutExtension(key)) {
            file = sub;
            _status = DownloadStatus.Complete;
            return;
          }
        }
      }
      _status = DownloadStatus.None;
    }
  }
  DownloadItem._setup(SetupState setupState) {
    _downloader = setupState.downloader;
    file = setupState.file;
    key = setupState.file.path.replaceFirst("${Configs().romsRoot.path}/", "");
    _loaded = setupState.state.loaded;
    _total = setupState.state.total;
    switch (setupState.state.status) {
      case Status.None:
        _setStatus(DownloadStatus.None);
        break;
      case Status.Downloading:
        _setStatus(DownloadStatus.Downloading);
        _processDownloader();
        break;
      case Status.Complete:
        _setStatus(DownloadStatus.Complete);
        break;
    }
  }

  void _setStatus(DownloadStatus status) {
    if (_status != status) {
      _status = status;
      onStatus?.call();
    }
  }

  int _loaded = 0;
  int _total = 0;
  int get loaded => _loaded;
  int get total => _total;

  void _updateProgress(int loaded, int total) {
    if (_loaded != loaded || _total != total) {
      _loaded = loaded;
      _total = total;
      onProgress?.call(_loaded, _total);
    }
  }

  void start({
    @required String url,
    Map<String, String> headers,
    @required String title,
    @required String description
  }) {
    if (status == DownloadStatus.None) {
      var uri = Uri.parse(url);
      file = File(path.withoutExtension(file.path) + path.extension(uri.path));
      _downloader = DownloaderManager().enqueue(
          url: url,
          headers: headers,
          file: file,
          title: title,
          description: description
      );
      _setStatus(DownloadStatus.Downloading);
      _processDownloader();
    }
  }

  void _processDownloader() {
    _timer = Timer.periodic(Duration(seconds: 5), (timer) async {
      DownloadState state = await _downloader.state();
      switch (state.status) {
        case Status.None:
          _setStatus(DownloadStatus.None);
          _cancelTimer();
          break;
        case Status.Downloading:
          _setStatus(DownloadStatus.Downloading);
          _updateProgress(state.loaded, state.total);
          break;
        case Status.Complete:
          _setStatus(DownloadStatus.Complete);
          _cancelTimer();
          break;
      }
    });
    _downloader.onComplete = () {
      _checkStatus();
    };
    _downloader.onClicked = () {
      print("Clicked!");
    };
  }

  void _cancelTimer() {
    _timer?.cancel();
    _timer = null;
  }

  void _checkStatus() async {
    _cancelTimer();
    _setStatus(await file.exists() ? DownloadStatus.Complete : DownloadStatus.None);
  }
}

class DownloadManager {
  DownloadManager._();

  static DownloadManager _manager;
  Map<String, DownloadItem> _downloads = {};

  factory DownloadManager() {
    if (_manager == null)
      _manager = DownloadManager._();
    return _manager;
  }

  DownloadItem operator[] (String key) {
    if (_downloads.containsKey(key)) {
      return _downloads[key];
    } else {
      DownloadItem item = DownloadItem._(key);
      _downloads[key] = item;
      return item;
    }
  }

  Future<void> setup() async {
    var res = await DownloaderManager().setup();
    for (var state in res) {
      var item = DownloadItem._setup(state);
      _downloads[item.key] = item;
    }
  }
}