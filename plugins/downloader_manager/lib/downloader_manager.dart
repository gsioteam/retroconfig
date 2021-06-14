
import 'dart:async';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

String calculateKey(String type, int id) => "${type}_$id";

enum Status {
  None,
  Downloading,
  Complete,
}

class DownloadState {
  Status status;
  int loaded;
  int total;

  DownloadState._();

  factory DownloadState.from(Map map) {
    return DownloadState._()
      ..status = Status.values[map["status"]]
      ..loaded = map["loaded"]
      ..total = map["total"];
  }
}

class Downloader {
  int id;
  DownloaderManager manager;
  Future<void> _ready;

  Downloader(this.manager);

  void start(dynamic arguments) async {
    Completer<void> completer = Completer();
    _ready = completer.future;
    id = await manager._enqueue(arguments);
    completer.complete();
  }

  void setCallback(String key, VoidCallback callback) {
    if (callback == null) {
      manager._callbacks.remove(key);
    } else {
      manager._callbacks[key] = callback;
    }
  }

  void _waitReady(VoidCallback callback) async {
    await _ready;
    callback();
  }

  set onComplete(VoidCallback callback) {
    _waitReady(() {
      setCallback(calculateKey("complete", id), callback);
    });
  }

  set onClicked(VoidCallback callback) {
    _waitReady(() {
      setCallback(calculateKey("click", id), callback);
    });
  }
  
  Future<DownloadState> state() async {
    await _ready;
    Map state = await manager._channel.invokeMethod("state", {
      "id": id
    });
    return DownloadState.from(state);
  }
}

class SetupState {
  Downloader downloader;
  DownloadState state;
  File file;
}

class DownloaderManager {
  static DownloaderManager _manager;

  factory DownloaderManager() {
    if (_manager == null)
      _manager = DownloaderManager._();
    return _manager;
  }

  MethodChannel _channel =
      const MethodChannel('downloader_manager');
  Map<String, VoidCallback> _callbacks = {};

  DownloaderManager._() {
    _channel.setMethodCallHandler(_methodHandler);
  }

  Future<List<SetupState>> setup() async {
    List res = await _channel.invokeMethod("setup");
    List<SetupState> list = [];
    for (int i = 0, t = res.length; i < t; ++i) {
      Map map = res[i];
      SetupState state = SetupState();
      state.downloader = Downloader(this)..id = map["id"];
      state.state = DownloadState.from(map);
      state.file = File.fromUri(Uri.parse(map["local"]));
      list.add(state);
    }
    return list;
  }

  Downloader enqueue({
    String url,
    Map<String, String> headers,
    File file,
    String title,
    String description
  }) {
    Downloader downloader = Downloader(this);
    downloader.start({
      "url": url,
      "headers": headers ?? {},
      "file": file.path,
      "title": title,
      "description": description
    });
    return downloader;
  }

  Future<int> _enqueue(dynamic arguments) async {
    return await _channel.invokeMethod<int>("enqueue", arguments);;
  }

  Future<dynamic> _methodHandler(MethodCall call) async {
    int id = call.arguments as int;
    String key = calculateKey(call.method, id);
    if (_callbacks.containsKey(key)) {
      _callbacks[key].call();
    }
  }
}
