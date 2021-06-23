
import 'package:flutter/material.dart';
import 'package:glib/main/project.dart';
import 'package:retroconfig/retroarch_dialog.dart';
import 'package:app_launcher/app_launcher.dart';
import 'package:retroconfig/utils/open_retroarch.dart';
import '../widgets/drawer_header.dart' as my;

import 'history.dart';
import 'index.dart';
import 'libraries.dart';
import 'settings.dart';
import '../localizations/localizations.dart';


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

bool _notDisabled()=>false;

class DrawerItem {
  Widget icon;
  String title;
  VoidCallback onPressed;
  ActionsController actionsController;
  Widget Function(BuildContext, ActionsController) builder;
  final bool defaultItem;
  final bool Function() isDisabled;
  final bool divider;

  DrawerItem({
    this.divider = false,
    this.title,
    this.icon,
    this.onPressed,
    this.builder,
    ActionsController actionsController,
    this.defaultItem = false,
    this.isDisabled = _notDisabled
  }) {
    this.actionsController = actionsController ?? ActionsController();
  }
}

class Home extends StatefulWidget  {
  Home();

  @override
  State<StatefulWidget> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  Widget body;
  int selected = -1;
  List<DrawerItem> items;

  @override
  Widget build(BuildContext context) {
    if (body == null) {
      if (selected < 0) {
        for (int i = 0, t = items.length; i < t; ++i) {
          var item = items[i];
          if (item.builder != null) {
            body = item.builder(context, item.actionsController);
            selected = i;
            break;
          }
        }
      } else {
        var item = items[selected];
        body = item.builder(context, item.actionsController);
      }
    }
    Widget title;
    List<Widget> actions;
    if (selected >= 0) {
      title = Text(kt(items[selected].title));
      actions = items[selected].actionsController.getActions();
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
          itemCount: items.length + 1,
          itemBuilder: drawerItem
        ),
      ),
      body: NotificationListener<LibraryNotification>(
        child: body,
        onNotification: (notification) {
          setState(() { });
          return true;
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

  Widget drawerItem(BuildContext context, int idx) {
    if (idx == 0) {
      return my.DrawerHeader();
    } else {
      --idx;

      var item = items[idx];
      if (item.divider) {
        return Divider();
      } else {
        bool disabled = item.isDisabled();
        return ListTile(
          enabled: !disabled,
          selected: selected == idx,
          leading: item.icon,
          title: Text(kt(item.title)),
          onTap: disabled ? null : () {
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
    }
  }

  @override
  void dispose() {
    super.dispose();

    for (var item in items) {
      item.actionsController.onChanged = null;
    }
  }

  @override
  void initState() {
    super.initState();
    _setupItems();

    for (int i = 0, t = items.length; i < t; ++i) {
      var item = items[i];
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

  void _setupItems() {
    items = [
      DrawerItem(
        icon: Icon(Icons.apps),
        title: "roms",
        builder: (context, actionsController) => Index(actionsController),
        isDisabled: () => Project.getMainProject() == null,
      ),
      DrawerItem(
          icon: Icon(Icons.history),
          title: "history",
          builder: (context, actionsController) => History(actionsController),
          actionsController: ActionsController()
            ..actions = [
              ActionItem()
                ..icon = Icon(Icons.clear_all)
                ..key = "clear"
            ]
      ),
      DrawerItem(
        divider: true,
      ),
      DrawerItem(
        icon: Icon(Icons.extension),
        title: "plugins",
        actionsController: ActionsController()
          ..actions = [
            ActionItem()
              ..icon = Icon(Icons.add)
              ..key = "add"
          ],
        builder: (context, actionsController) => Libraries(actionsController),
        defaultItem: Project.getMainProject() == null,
      ),
      DrawerItem(
        divider: true,
      ),
      DrawerItem(
        icon: Icon(Icons.settings),
        title: "settings",
        builder: (context, actionsController) => Settings(),
      )
    ];
  }
}