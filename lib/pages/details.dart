
import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:glib/core/array.dart';
import 'package:glib/core/gmap.dart';
import 'package:glib/main/context.dart';
import 'package:glib/main/data_item.dart';
import 'package:glib/main/models.dart';
import 'package:glib/main/project.dart';
import 'package:retroconfig/utils/download_manager.dart';
import 'package:retroconfig/utils/history_manager.dart';
import 'package:retroconfig/utils/open_retroarch.dart';
import 'package:retroconfig/utils/retroarch_config.dart';
import 'package:xml_layout/xml_layout.dart';
import '../configs.dart';
import '../widgets/collection_view.dart';
import 'package:crypto/crypto.dart';
import 'package:convert/convert.dart';
import 'package:filesystem_picker/filesystem_picker.dart';

import '../localizations/localizations.dart';

Future<void> gotoDetails(BuildContext context, {
  Project project,
  Context itemContext,
}) {
  return Navigator.of(context).push(MaterialPageRoute(
    builder: (context) {
      return Details(
        project: project,
        context: itemContext
      );
    }
  ));
}

class Details extends StatefulWidget {
  final Project project;
  final Context context;

  Details({
    @required this.project,
    @required this.context
  });

  @override
  State<StatefulWidget> createState() => DetailsState();
}

class DetailsState extends State<Details> {
  String template;
  GlobalKey _key = GlobalKey();

  Future<Directory> getRootDirectory() async {
    String path = KeyValue.get(old_selected_key);
    if (path != null && path.isNotEmpty) {
      Directory ret = Directory(path);
      if (await ret.exists()) {
        return ret;
      }
    }
    return Configs().romsRoot;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CollectionView(
        key: _key,
        context: widget.context,
        template: template,
        onTap: (DataItem item) async {

        },
        extensions: {
          "installLocalRom": () async {
            var rootDir = await getRootDirectory();
            String path = await FilesystemPicker.open(
              title: kt("select_rom"),
              context: context,
              rootDirectory: Directory("/storage/emulated/0"),
              fsType: FilesystemType.file,
              folderIconColor: Theme.of(context).colorScheme.primary,
              fileTileSelectMode: FileTileSelectMode.wholeTile,
              initialDirectory: rootDir,
            );
            File romFile = File(path);
            if (!await romFile.exists()) {
              Fluttertoast.showToast(msg: kt("file_not_exist"));
              return;
            }
            KeyValue.set(old_selected_key, romFile.parent.path);
            DataItem currentData = widget.context.infoData;
            String type = currentData.data["type"];
            String cover = currentData.data["cover"];
            Array array = currentData.data["images"];
            String title = currentData.title;

            bool ret = await showDialog<bool>(
                context: context,
                builder: (context) {
                  return AlertDialog(
                    title: Text(kt("write_config")),
                    content: Text(kt("check_write_config").replaceFirst("{0}", romFile.path).replaceFirst("{1}", title)),
                    actions: [
                      TextButton(onPressed: () {
                        Navigator.of(context).pop(true);
                      }, child: Text(kt("yes"))),
                      TextButton(onPressed: () {
                        Navigator.of(context).pop(false);
                      }, child: Text(kt("no"))),
                    ],
                  );
                }
            );
            if (ret != true) return;

            try {
              List images = [];
              if (array != null && array.length > 0) {
                for (var src in array) {
                  images.add(src);
                }
              } else {
                images = [cover];
              }
              await RetroArchConfig.install(
                type: type,
                romFile: romFile,
                cover: cover,
                images: images,
                name: title,
              );
            } catch (e) {
              Fluttertoast.showToast(msg: "Install failed!");
            }
          }
        },
        onDataChanged: () {
          HistoryManager().insert(widget.context.infoData);
        },
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Launch RetroArch',
        child: Image(
          image: AssetImage("assets/retroarch.png")
        ),
        onPressed: () => openRetroArch(context),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    widget.project.control();
    widget.context.control();

    HistoryManager().insert(widget.context.infoData);
    template = widget.context.temp;
    if (template.isEmpty)
      template = cachedTemplates["assets/details.xml"];
  }

  @override
  void dispose() {
    super.dispose();
    widget.project.release();
    widget.context.release();
  }
}