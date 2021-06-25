
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:glib/core/array.dart';
import 'package:glib/core/gmap.dart';
import 'package:glib/main/context.dart';
import 'package:glib/main/data_item.dart';
import 'package:url_launcher/url_launcher.dart';
import '../utils/download_manager.dart';
import 'package:crypto/crypto.dart';
import 'package:convert/convert.dart';
import 'dart:convert';
import 'package:path/path.dart' as path;
import '../utils/retroarch_config.dart';
import '../webview.dart';
import '../localizations/localizations.dart';

class DownloadWidget extends StatefulWidget {
  final Widget Function(BuildContext context, Map<String, dynamic> status) builder;
  final Context context;
  final int index;

  DownloadWidget({
    this.builder,
    this.context,
    this.index,
  });

  @override
  State<StatefulWidget> createState() => DownloadWidgetState();
}

class DownloadWidgetState extends State<DownloadWidget> {

  DownloadItem downloadItem;
  String link;
  String title;
  String subtitle;
  Map<String, String> headers;

  String type;
  String cover;
  List<String> images;
  String downloadType;

  @override
  Widget build(BuildContext context) {
    double progress = downloadItem.total > 0 ? (downloadItem.loaded / downloadItem.total) : 0;

    return widget.builder(context, {
      "status": downloadType == "webview" ? 3 : downloadItem.status.index,
      "progress": progress,
      "title": title,
      "subtitle": subtitle,
      "loaded": downloadItem.loaded,
      "total": downloadItem.total,
      "start": () {
        if (downloadType == 'direct') {
          if (downloadItem.status == DownloadStatus.None)
            downloadItem.start(
                url: link,
                headers: headers,
                title: title,
                description: subtitle);
        } else if (downloadType == 'webview') {
          launch(link);
        }
      },
      "install": () async {
        if (downloadItem.status == DownloadStatus.Complete) {
          try {
            await RetroArchConfig.install(
              type: type,
              romFile: downloadItem.file,
              cover: cover,
              images: images,
              name: title,
            );
          } catch (e, stack) {
            print(e);
            print(stack);
            Fluttertoast.showToast(msg: kt("write_config_failed"));
            return;
          }
          Fluttertoast.showToast(msg: kt("write_config_success"));
        } else {
          Fluttertoast.showToast(msg: kt("not_complete"));
        }
      }
    });
  }

  void updateWidget() {
    DataItem item = widget.context.data[widget.index];
    DataItem currentData = widget.context.infoData;
    link = item.link;
    Uri uri = Uri.parse(link);
    title = currentData.title;
    subtitle = currentData.subtitle;
    String itemLink = currentData.link;
    GMap data = item.data;
    downloadType = 'direct';
    if (data != null) {
      if (data.containsKey("headers")) {
        headers = {};
        headers.addAll(data["headers"]);
      }
      if (data.containsKey('type')) {
        downloadType = data['type'];
      }
    } else {
      headers = null;
    }
    type = currentData.data["type"];
    cover = currentData.data["cover"];
    Array images = currentData.data["images"];
    if (images != null && images.length > 0) {
      this.images = [];
      for (var src in images) {
        this.images.add(src);
      }
    } else {
      this.images = [cover];
    }
    String key = "$type/${path.basename(uri.path)}";
    var dItem = DownloadManager()[key];
    if (downloadItem != dItem) {
      downloadItem = dItem;
      downloadItem.customData = itemLink;
      downloadItem.onStatus = () {
        setState(() {});
      };
      downloadItem.onProgress = (loaded, total) {
        setState(() {});
      };
    }
  }

  @override
  void didUpdateWidget(covariant DownloadWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    updateWidget();
  }

  @override
  void initState() {
    super.initState();

    updateWidget();
  }

  @override
  void dispose() {
    super.dispose();
  }
}