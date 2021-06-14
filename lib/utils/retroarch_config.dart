
import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:retroconfig/configs.dart';
import 'package:crclib/crclib.dart';
import 'package:crclib/catalog.dart';
import 'package:path/path.dart' as path;
import 'package:image/image.dart';
import 'package:image/image.dart' as image;

class RetroArchConfig {
  static Future<void> install({
    String type,
    File romFile,
    String cover,
    List<String> images,
    String name,
    BaseCacheManager cacheManager,
  }) async {
    Directory dir = Directory("${Configs().retroArchRoot.path}/playlists");
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    String dbName = "$type.lpl";
    File configFile = File("${dir.path}/$dbName");
    List<Map<String, dynamic>> configs = [];
    if (await configFile.exists()) {
      var data = jsonDecode(await utf8.decodeStream(configFile.openRead()));
      for (var item in data["items"]) {
        configs.add(item);
      }
    }

    CrcValue crc32 = await romFile.openRead().transform(Crc32Xz()).single;
    configs.removeWhere((element) {
      return element["path"] == romFile.path;
    });
    configs.insert(0, {
      "path": romFile.path,
      "label": name,
      "core_path": "DETECT",
      "core_name": "DETECT",
      "crc32": "DETECT",
      "db_name": dbName
    });
    await configFile.writeAsString(jsonEncode({
      "version": "1.0",
      "items": configs
    }));

    String typeName = path.basenameWithoutExtension(dbName);
    dir = await _thumbnailsDir(typeName, "Named_Titles");
    if (cacheManager == null)
      cacheManager = DefaultCacheManager();

    String transformedName = name.replaceAll(RegExp("[&*/:`<>?\\|]"), "_");
    // String ext = path.extension(cover);
    File file = await cacheManager.getSingleFile(cover);
    var imageBuffer = PngEncoder().encodeImage(decodeImage(await file.readAsBytes()));

    await File("${dir.path}/$transformedName.png").writeAsBytes(imageBuffer);

    dir = await _thumbnailsDir(typeName, "Named_Boxarts");
    await File("${dir.path}/$transformedName.png").writeAsBytes(imageBuffer);
    
    dir = await _thumbnailsDir(typeName, "Named_Snaps");
    if (images.length == 0) {
      await File("${dir.path}/$transformedName.png").writeAsBytes(imageBuffer);
    } else if (images.length > 1) {
      var animation = image.Animation();
      for (var src in images) {
        File file = await cacheManager.getSingleFile(src);
        animation.addFrame(decodeImage(await file.readAsBytes()));
      }
      var imageBuffer = PngEncoder().encodeAnimation(animation);
      await File("${dir.path}/$transformedName.png").writeAsBytes(imageBuffer);
    }  else {
      file = await cacheManager.getSingleFile(images.first);
      var imageBuffer = PngEncoder().encodeImage(decodeImage(await file.readAsBytes()));
      await File("${dir.path}/$transformedName.png").writeAsBytes(imageBuffer);
    }
  }

  static Future<Directory> _thumbnailsDir(String type, String name) async {
    Directory dir = Directory("${Configs().retroArchRoot.path}/thumbnails/$type/$name");
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

}