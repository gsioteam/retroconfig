import 'package:expandable_text/expandable_text.dart';
import 'package:flutter/material.dart';
import 'package:retroconfig/widgets/download_widget.dart';
import '../widgets/web_image.dart';
import '../widgets/better_refresh_indicator.dart';

const List<String> imports = [
  'package:flutter/cupertino.dart'
];

const Map<String, String> converts = {
  "package:vector_math/src/vector_math_64/": "package:vector_math/vector_math_64.dart",
  "package:vector_math/src/vector_math/": "package:vector_math/vector_math.dart",
};

const Map<Type, Type> convertTypes = {
  EdgeInsetsGeometry: EdgeInsets
};

const List<Type> types = [
  MaterialButton,
  Column,
  Scaffold,
  Text,
  Icon,
  GridView,
  Container,
  MaterialButton,
  AppBar,
  Image,
  ListView,
  WebImage,
  BetterRefreshIndicator,
  Divider,
  ListTile,
  Row,
  Padding,
  ExpandableText,
  DownloadWidget,
  TextButton,
  IconButton,
];