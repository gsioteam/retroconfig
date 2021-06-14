
import 'package:flutter/material.dart';
import 'package:glib/core/callback.dart';
import 'package:glib/glib.dart';
import 'package:glib/main/context.dart';
import 'package:glib/core/array.dart';
import 'package:glib/main/data_item.dart';
import 'package:glib/main/error.dart' as glib;
import 'package:glib/core/gmap.dart';
import 'package:glib/core/array.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:xml_layout/types/function.dart';
import 'package:xml_layout/xml_layout.dart';

import 'better_refresh_indicator.dart';

import '../layout/layout.xml_layout.dart' as layout;
import '../layout/widgets.xml_layout.dart' as widgets;
import 'package:xml_layout/types/colors.dart' as colors;
import 'package:xml_layout/types/icons.dart' as icons;

bool _fistInit = true;

class CollectionView extends StatefulWidget {
  final Context context;
  final String template;
  final void Function(DataItem item) onTap;
  final Map<String, dynamic> extensions;

  CollectionView({
    Key key,
    @required this.context,
    @required this.template,
    this.onTap,
    this.extensions
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => CollectionViewState();
}

class CollectionViewState extends State<CollectionView> {

  BetterRefreshIndicatorController refreshController = BetterRefreshIndicatorController();
  Map<String, dynamic> dataCache = {};

  @override
  Widget build(BuildContext context) {
    if (_fistInit) {
      _fistInit = false;
      icons.register();
      colors.register();
      layout.register();
      widgets.register();
      registerReturnType<Widget>();
    }

    Map<String, dynamic> objects = {
      "refreshController": refreshController,
      "itemCount": widget.context.data.length,
      "context": widget.context,
      "getItem": (int idx) {
        DataItem item = widget.context.data[idx];
        Map<String, dynamic> data = dataCache[item.link];
        if (data == null) {
          data = processData(item);
          dataCache[item.link] = data;
        }
        return data;
      },
      "infoData": processData(widget.context.infoData),
      "onTap": (int idx) {
        widget.onTap?.call(widget.context.data[idx]);
      }
    };
    if (widget.extensions != null)
      objects.addAll(widget.extensions);
    return XmlLayout(
      template: widget.template,
      objects: objects,
    );
  }

  dynamic processData(dynamic data) {
    if (data is DataItem) {
      DataItem item = data;
      return {
        "title": item.title,
        "data": processData(item.data),
        "summary": item.summary,
        "picture": item.picture,
        "subtitle": item.subtitle,
        "link": item.link,
        "type": item.type,
        "isHeader": item.type == DataItemType.Header
      };
    } else if (data is GMap) {
      Map<String, dynamic> map = {};
      data.forEach((key, value) {
        map[key] = processData(value);
      });
      return map;
    } else if (data is Array) {
      List list = [];
      data.forEach((element) {
        list.add(processData(element));
      });
      return list;
    } else {
      return data;
    }
  }

  void onDataChanged(int type, Array data, int idx) {
    setState(() { });
  }

  void onLoadingStatus(bool isLoading) {
    if (isLoading) refreshController.startLoading();
    else refreshController.stopLoading();
  }

  void onError(glib.Error error) {
    Fluttertoast.showToast(
      msg: error.msg,
      toastLength: Toast.LENGTH_SHORT,
    );
  }

  bool onRefresh() {
    widget.context.reload();
    return false;
  }

  void onLoadMore() {
    widget.context.loadMore();
  }

  @override
  void initState() {
    super.initState();
    refreshController.onRefresh = onRefresh;
    refreshController.onLoadMore = onLoadMore;
    widget.context.control();
    widget.context.onDataChanged = Callback.fromFunction(onDataChanged).release();
    widget.context.onLoadingStatus = Callback.fromFunction(onLoadingStatus).release();
    widget.context.onError = Callback.fromFunction(onError).release();
    widget.context.enterView();
  }

  @override
  void dispose() {
    super.dispose();
    refreshController.onRefresh = null;
    refreshController.onLoadMore = null;
    widget.context.exitView();
    widget.context.onDataChanged = null;
    widget.context.onLoadingStatus = null;
    widget.context.onError = null;
    widget.context.release();
  }
}