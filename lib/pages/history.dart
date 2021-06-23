
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:glib/main/context.dart';
import 'package:glib/main/data_item.dart';
import 'package:glib/main/project.dart';
import 'package:retroconfig/pages/details.dart';
import 'package:retroconfig/utils/history_manager.dart';
import 'package:retroconfig/widgets/collection_view.dart';
import 'package:retroconfig/widgets/web_image.dart';
import 'package:xml_layout/xml_layout.dart';

import '../localizations/localizations.dart';
import '../configs.dart';
import 'home.dart';

class History extends StatefulWidget {

  final ActionsController controller;

  History(this.controller);

  @override
  State<StatefulWidget> createState() => HistoryState();
}

class HistoryState extends State<History> {
  @override
  Widget build(BuildContext context) {
    var items = HistoryManager().items;
    return ListView.separated(
      itemBuilder: (context, index) {
        var item = items[index];
        var data = item.item;
        return ListTile(
          title: Text(data.title),
          subtitle: Text(data.subtitle),
          leading: data.picture.isNotEmpty ? WebImage(
            url: data.picture,
            fit: BoxFit.cover,
            width: 56,
            height: 56,
          ) : null,
          onTap: () {
            enterPage(item);
          },
        );
      },
      separatorBuilder: (context, idx) => Divider(),
      itemCount: items.length
    );
  }


  void enterPage(HistoryItem historyItem) async {
    DataItem item = historyItem.item;
    Project project = Project.allocate(item.projectKey);
    if (!project.isValidated) {
      Fluttertoast.showToast(msg: kt("no_project_found"));
      project.release();
      return;
    }
    Context ctx = project.createCollectionContext(DETAILS_INDEX, item).control();
    await gotoDetails(context,
      project: project,
      itemContext: ctx
    );
    ctx.release();
    project.release();
  }

  @override
  void initState() {
    super.initState();
    HistoryManager().onChange = () async {
      await Future.delayed(Duration(milliseconds: 100));
      setState(() { });
    };
    widget.controller.onClicked = onAction;
  }

  @override
  void dispose() {
    super.dispose();
    HistoryManager().onChange = null;
    widget.controller.onClicked = null;
  }

  void onAction(String action) async {
    if (action == "clear") {
      bool check = await showDialog<bool>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text(kt("clear_history")),
            content: Text(kt("check_clear_history")),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(true);
                },
                child: Text(kt("yes"))
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(false);
                },
                child: Text(kt("no"))
              )
            ],
          );
        }
      );
      if (check == true)
        HistoryManager().clear();
    }
  }
}