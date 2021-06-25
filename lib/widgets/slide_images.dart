
import 'package:flutter/material.dart';
import 'package:flutter_image_slideshow/flutter_image_slideshow.dart';
import 'package:photo_view/photo_view.dart';

class SlideImages extends StatelessWidget {
  final List<Widget> children;
  final double width;
  final double height;
  final int initialPage;
  final Color indicatorColor;
  final Color indicatorBackgroundColor;
  final void Function(int) onPageChanged;
  final int autoPlayInterval;

  SlideImages({
    this.children,
    this.width = double.infinity,
    this.height = 200,
    this.initialPage = 0,
    this.indicatorColor = Colors.blue,
    this.indicatorBackgroundColor,
    this.onPageChanged,
    this.autoPlayInterval,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      child: ImageSlideshow(
        children: children.map<Widget>((e) {
          return FittedBox(
            fit: BoxFit.cover,
            child: e,
          );
        }).toList(),
        width: width,
        height: height,
        initialPage: initialPage,
        indicatorColor: indicatorColor ?? Theme.of(context).colorScheme.primary,
        indicatorBackgroundColor: indicatorBackgroundColor ?? Theme.of(context).backgroundColor,
        onPageChanged: onPageChanged,
        autoPlayInterval: autoPlayInterval
      ),
      onTap: () {
        showDialog(
          context: context,
          builder: (context) {
            return Container(
              child: PageView(
                children: children.map<Widget>((e) {
                  return PhotoView.customChild(
                    child: FittedBox(
                      fit: BoxFit.contain,
                      child: e,
                    ),
                    backgroundDecoration: BoxDecoration(
                      color: Colors.transparent
                    ),
                    onTapUp: (context, details, value) {
                      Navigator.of(context).pop();
                    },
                  );
                }).toList(),
              ),
            );
          }
        );
      },
    );
  }
}