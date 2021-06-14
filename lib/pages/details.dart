
import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:glib/core/gmap.dart';
import 'package:glib/main/context.dart';
import 'package:glib/main/data_item.dart';
import 'package:glib/main/project.dart';
import 'package:retroconfig/utils/download_manager.dart';
import 'package:retroconfig/utils/open_retroarch.dart';
import 'package:xml_layout/xml_layout.dart';
import '../configs.dart';
import '../widgets/collection_view.dart';
import 'package:crypto/crypto.dart';
import 'package:convert/convert.dart';

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

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      body: CollectionView(
        key: _key,
        context: widget.context,
        template: template,
        onTap: (DataItem item) async {

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