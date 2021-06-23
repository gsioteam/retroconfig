
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

const String retroarch_playlists_key = "RetroArchPlaylists";
const String retroarch_thumbnails_key = "RetroArchThumbnails";
const String roms_root_key = "RomsRoot";
const String old_selected_key = "OldSelected";
const String tab_key = "tab";
const String history_key = "history";
const String disclaimer_key = "disclaimer";

const String home_path = "home";

class Configs {
  static Configs _instance;

  Directory _retroArchPlaylists;
  Directory _retroArchThumbnails;
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
    _retroArchPlaylists = await _defaultDirectory(retroarch_playlists_key, "RetroArch/playlists");
    _retroArchThumbnails = await _defaultDirectory(retroarch_thumbnails_key, "RetroArch/thumbnails");
    if (!await _retroArchPlaylists.exists()) {
      await _retroArchPlaylists.create(recursive: true);
    }
    _romsRoot = await _defaultDirectory(roms_root_key, "ROMs");
    if (!await _romsRoot.exists()) {
      await _romsRoot.create(recursive: true);
    }
  }

  Directory get retroArchPlaylists => _retroArchPlaylists;
  set retroArchPlaylists(Directory directory) {
    if (directory.existsSync()) {
      _retroArchPlaylists = directory;
      KeyValue.set(retroarch_playlists_key, directory.path);
    }
  }

  Directory get retroArchThumbnails => _retroArchThumbnails;
  set retroArchThumbnails(Directory directory) {
    if (directory.existsSync()) {
      _retroArchThumbnails = directory;
      KeyValue.set(retroarch_thumbnails_key, directory.path);
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