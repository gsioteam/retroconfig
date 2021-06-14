
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:glib/main/models.dart';
import 'package:glib/utils/git_repository.dart';
import 'package:path_provider/path_provider.dart' as path_provider;
import 'package:permission_handler/permission_handler.dart';

const String env_git_url = "https://github.com/gsioteam/glib_env.git";
const String env_git_branch = "master";

GitRepository envRepo;

const DETAILS_INDEX = 0;

const String language_key = "language";

Map<String, String> cachedTemplates = {};

const String retroarch_root_key = "RetroArchRoot";
const String roms_root_key = "RomsRoot";
const String tab_key = "tab";

class Configs {
  static Configs _instance;

  Directory _retroArchRoot;
  Directory _romsRoot;

  Configs._();
  factory Configs() {
    if (_instance == null)
      _instance = Configs._();
    return _instance;
  }

  Future<void> setup() async {
    var status = await Permission.storage.status;
    switch (status) {
      case PermissionStatus.granted:
        break;
      default: {
        var status = await Permission.storage.request();
        if (status != PermissionStatus.granted) {
          Fluttertoast.showToast(
              msg: "no_permission"
          );
          return;
        }
      }
    }
    _retroArchRoot = await _defaultDirectory(retroarch_root_key, "RetroArch");
    if (!await _retroArchRoot.exists()) {
      await _retroArchRoot.create(recursive: true);
    }
    _romsRoot = await _defaultDirectory(roms_root_key, "ROMs");
    if (!await _romsRoot.exists()) {
      await _romsRoot.create(recursive: true);
    }
  }

  Directory get retroArchRoot => _retroArchRoot;
  set retroArchRoot(Directory directory) {
    if (directory.existsSync()) {
      _retroArchRoot = directory;
      KeyValue.set(retroarch_root_key, directory.path);
    }
  }

  Directory get romsRoot => _romsRoot;
  set romsRoot(Directory directory) {
    if (directory.existsSync()) {
      _romsRoot = directory;
      KeyValue.set(roms_root_key, directory.path);
    }
  }

  Future<Directory> _defaultDirectory(String key, String dirName) async {
    String path = KeyValue.get(key);
    Directory root = Directory("/storage/emulated/0");
    if (!await root.exists()) {
      root = await path_provider.getExternalStorageDirectory();
    }
    if (path == null || path.isEmpty) {
      return Directory("${root.path}/$dirName");
    } else {
      Directory directory = Directory(path);
      if (await directory.exists()) {
        return directory;
      } else {
        return Directory("${root.path}/$dirName");
      }
    }
  }
}