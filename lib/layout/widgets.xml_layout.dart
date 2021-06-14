import 'package:xml_layout/xml_layout.dart';
import 'package:xml_layout/register.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_image_slideshow/flutter_image_slideshow.dart';
import 'dart:ui';
import 'package:flutter/src/foundation/basic_types.dart';

Register register = Register(() {
  XmlLayout.register("ImageSlideshow", (node, key) {
    return ImageSlideshow(
        children: node.children<Widget>(),
        width: node.s<double>("width", double.infinity),
        height: node.s<double>("height", 200),
        initialPage: node.s<int>("initialPage", 0),
        indicatorColor: node.s<Color>("indicatorColor", Colors.blue),
        indicatorBackgroundColor:
            node.s<Color>("indicatorBackgroundColor", Colors.grey),
        onPageChanged: node.s<void Function(int)>("onPageChanged"),
        autoPlayInterval: node.s<int>("autoPlayInterval"));
  });
  XmlLayout.registerInline(Color, "", false, (node, method) {
    return Color(method[0]?.toInt());
  });
  XmlLayout.registerInline(Color, "fromARGB", false, (node, method) {
    return Color.fromARGB(method[0]?.toInt(), method[1]?.toInt(),
        method[2]?.toInt(), method[3]?.toInt());
  });
  XmlLayout.registerInline(Color, "fromRGBO", false, (node, method) {
    return Color.fromRGBO(method[0]?.toInt(), method[1]?.toInt(),
        method[2]?.toInt(), method[3]?.toDouble());
  });
});
