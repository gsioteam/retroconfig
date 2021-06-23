
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_material_pickers/flutter_material_pickers.dart' as picker;
import 'package:glib/core/gmap.dart';
import 'package:glib/main/context.dart';
import 'package:glib/main/models.dart';
import 'package:glib/main/project.dart';
import 'package:retroconfig/configs.dart';
import 'package:retroconfig/pages/search.dart';
import 'package:retroconfig/widgets/collection_view.dart';
import 'home.dart';
import 'roms.dart';
import 'dart:math' as math;
import '../localizations/localizations.dart';

class _CollectionData {
  Context context;
  String title;

  _CollectionData(this.context, this.title);
}

class Index extends StatefulWidget {

  final ActionsController controller;

  Index(this.controller);
  
  @override
  State<StatefulWidget> createState() => IndexState();
}

const String _searchKey = "search";

class IndexItem {
  final String name;
  final int value;

  IndexItem(this.name, this.value);

  @override
  String toString() => name;
}

class IndexState extends State<Index> with TickerProviderStateMixin {
  List<_CollectionData> contexts = [];
  Project project;
  TabController tabController;
  GlobalKey searchKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    List<Widget> tabs = [];
    List<Widget> bodies = [];
    List<IndexItem> items = [];
    for (int i = 0, t = contexts.length; i < t; ++i) {
      _CollectionData data = contexts[i];
      tabs.add(Container(
        child: Tab( text: data.title, ),
        height: 36,
      ));
      bodies.add(Roms(project, data.context));
      items.add(IndexItem(data.title, i));
    }
    return DefaultTabController(
      length: contexts.length,
      child: Scaffold(
        appBar: tabs.length > 1 ? AppBar(
          toolbarHeight: 36,
          elevation: 0,
          centerTitle: true,
          title: TabBar(
            tabs: tabs,
            isScrollable: true,
            indicatorColor: Colors.white,
            controller: tabController,
          ),
          automaticallyImplyLeading: false,
          actions: tabs.length <= 4 ? null : [
            IconButton(
              icon: Icon(Icons.arrow_drop_down),
              onPressed: () async {
                IndexItem item = await picker.showMaterialScrollPicker(
                  title: kt('index_select'),
                  context: context,
                  items: items,
                  selectedItem: items[tabController.index]
                );
                if (item != null)
                  tabController.index = item.value;
              },
            )
          ],
        ) : null,
        body: TabBarView(
          children: bodies,
          controller: tabController,
        ),
      ),
    );
  }

  String get tabKey => "$tab_key:${project.url}";

  @override
  void initState() {
    super.initState();
    project = Project.getMainProject()?.control();
    if (project != null) {
      for (GMap category in project.categories) {
        String title = category["title"];
        if (title == null) title = "";
        var ctx = project.createIndexContext(category).control();
        contexts.add(_CollectionData(ctx, title));
      }

      int tabIdx = 0;
      String tabStr = KeyValue.get(tabKey);
      if (tabStr != null && tabKey.isNotEmpty) {
        tabIdx = int.tryParse(tabStr) ?? 0;
      }
      if (tabIdx >= contexts.length) {
        tabIdx = math.max(0, contexts.length - 1);
      }
      tabController = TabController(
        length: contexts.length,
        vsync: this,
        initialIndex: tabIdx
      );
      tabController.addListener(_onTab);

      widget.controller.actions = project.search?.isNotEmpty == true ? [
        ActionItem()
          ..icon = Icon(Icons.search, key: searchKey,)
          ..key = _searchKey
      ] : [];
      widget.controller.onClicked = _onAction;
    }

  }

  @override
  void didUpdateWidget(covariant Index oldWidget) {
    super.didUpdateWidget(oldWidget);

    widget.controller.actions = project.search?.isNotEmpty == true ? [
      ActionItem()
        ..icon = Icon(Icons.search, key: searchKey,)
        ..key = _searchKey
    ] : [];
    widget.controller.onClicked = _onAction;
  }
  
  @override
  void dispose() {
    tabController.dispose();
    super.dispose();
    project?.release();
    for (var context in contexts) {
      context.context.release();
    }
    widget.controller.onClicked = null;
  }

  void _onTab() {
    KeyValue.set(tabKey, tabController.index.toString());
  }

  void _onAction(String key) async {
    if (key == _searchKey) {
      RenderObject object = searchKey.currentContext?.findRenderObject();
      var translation = object?.getTransformTo(null)?.getTranslation();
      var size = object?.semanticBounds?.size;
      Offset center;
      if (translation != null) {
        double x = translation.x, y = translation.y;
        if (size != null) {
          x += size.width / 2;
          y += size.height / 2;
        }
        center = Offset(x, y);
      } else {
        center = Offset(0, 0);
      }


      Context ctx = project.createSearchContext().control();
      await gotoSearchPage(
        builder: (context) {
          return Search(context: ctx, project: project,);
        },
        context: context,
        center: center
      );
      ctx.release();
    }
  }
}