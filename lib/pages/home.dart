
import 'package:flutter/material.dart';
import 'package:retroconfig/retroarch_dialog.dart';
import 'package:app_launcher/app_launcher.dart';
import 'package:retroconfig/utils/open_retroarch.dart';


class ActionItem {
  Icon icon;
  String key;
}

class ActionsController {
  List<ActionItem> _actions = [];
  void Function(String key) onClicked;
  VoidCallback onChanged;

  set actions(List<ActionItem> list) {
    _actions = list;
    onChanged?.call();
  }

  List<Widget> getActions() {
    return _actions.map((e) {
      return IconButton(
          icon: e.icon,
          onPressed: () {
            onClicked?.call(e.key);
          }
      );
    }).toList();
  }

  ActionsController();
}

class DrawerItem {
  Widget icon;
  Widget title;
  VoidCallback onPressed;
  ActionsController actionsController;
  Widget Function(BuildContext, ActionsController) builder;
  final bool defaultItem;

  DrawerItem({
    @required this.title,
    this.icon,
    this.onPressed,
    this.builder,
    ActionsController actionsController,
    this.defaultItem = false
  }) {
    this.actionsController = actionsController ?? ActionsController();
  }
}

class Home extends StatefulWidget  {
  final List<DrawerItem> items;

  Home({@required this.items});

  @override
  State<StatefulWidget> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  Widget body;
  int selected = -1;

  @override
  Widget build(BuildContext context) {
    if (body == null) {
      if (selected < 0) {
        for (int i = 0, t = widget.items.length; i < t; ++i) {
          var item = widget.items[i];
          if (item.builder != null) {
            body = item.builder(context, item.actionsController);
            selected = i;
            break;
          }
        }
      } else {
        var item = widget.items[selected];
        body = item.builder(context, item.actionsController);
      }
    }
    Widget title;
    List<Widget> actions;
    if (selected >= 0) {
      title = widget.items[selected].title;
      actions = widget.items[selected].actionsController.getActions();
    }

    return Scaffold(
      appBar: AppBar(
        title: title,
        actions: actions,
        elevation: 0,
      ),
      drawer: Drawer(
        child: ListView.builder(
          physics: ClampingScrollPhysics(),
          itemCount: widget.items.length,
          itemBuilder: drawerItem
        ),
      ),
      body: body,
      floatingActionButton: FloatingActionButton(
        tooltip: 'Launch RetroArch',
        child: Image(
          image: AssetImage("assets/retroarch.png")
        ),
        onPressed: () => openRetroArch(context),
      ),
    );
  }

  Widget drawerItem(BuildContext context, int idx) {
    var item = widget.items[idx];
    return ListTile(
      selected: selected == idx,
      leading: item.icon,
      title: item.title,
      onTap: () {
        if (selected == idx) return;
        if (item.builder == null) {
          item.onPressed?.call();
        } else {
          setState(() {
            body = item.builder(context, item.actionsController);
            selected = idx;
          });
        }
        Navigator.of(context).pop();
      },
    );
  }

  @override
  void dispose() {
    super.dispose();

    for (var item in widget.items) {
      item.actionsController.onChanged = null;
    }
  }

  @override
  void initState() {
    super.initState();

    for (int i = 0, t = widget.items.length; i < t; ++i) {
      var item = widget.items[i];
      if (item.defaultItem == true)
        selected = i;

      item.actionsController.onChanged = () {
        actionUpdate(i);
      };
    }
  }



  void actionUpdate(int idx) async {
    if (selected == idx) {
      await Future.delayed(Duration(milliseconds: 100));
      setState(() {});
    }
  }
}