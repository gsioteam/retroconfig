
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:glib/main/context.dart';
import 'package:glib/main/data_item.dart';
import 'package:glib/main/project.dart';
import 'package:retroconfig/pages/details.dart';
import 'package:retroconfig/widgets/collection_view.dart';

import '../configs.dart';

class Roms extends StatefulWidget {

  final Project project;
  final Context context;

  Roms(this.project, this.context);

  @override
  State<StatefulWidget> createState() => RomsState();
}

class RomsState extends State<Roms> {
  String template;

  @override
  Widget build(BuildContext context) {
    return CollectionView(
      context: widget.context,
      template: template,
      onTap: (DataItem item) async {
        if (item.type == DataItemType.Data) {
          Context itemContext = widget.project.createCollectionContext(DETAILS_INDEX, item).control();
          await gotoDetails(
            context,
            project: widget.project,
            itemContext: itemContext
          );
          itemContext.release();
        }
      },
    );
  }

  @override
  void initState() {
    super.initState();
    widget.context.control();

    template = widget.context.temp;
    if (template.isEmpty)
      template = cachedTemplates["assets/roms.xml"];
  }

  @override
  void dispose() {
    super.dispose();
    widget.context.release();
  }
}