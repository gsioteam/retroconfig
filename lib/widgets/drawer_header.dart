
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:glib/main/project.dart';
import 'package:glib/utils/git_repository.dart';
import 'package:retroconfig/widgets/web_image.dart';
import '../configs.dart';
import '../localizations/localizations.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

class DrawerHeader extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => DrawerHeaderState();
}

class OvalClipper extends CustomClipper<Rect> {
  @override
  Rect getClip(Size size) {
    return Rect.fromLTRB(0, 0, size.width, size.height);
  }

  @override
  bool shouldReclip(CustomClipper<Rect> oldClipper) {
    return false;
  }

}

class DrawerHeaderState extends State<DrawerHeader> with SingleTickerProviderStateMixin {

  AnimationController controller;
  bool isFetch = false;
  bool isCheckout = false;
  bool isDisposed = false;

  void startFetch() {
    if (isFetch) return;
    isFetch = true;
    controller.repeat();
    GitRepository repo = envRepo;
    GitAction action = repo.fetch();
    action.control();
    action.setOnComplete(() {
      action.release();
      if (isDisposed) return;
      this.setState(() {
        // if (this.onRefresh != null) this.onRefresh();
        controller.stop();
        controller.reset();
        isFetch = false;
      });
      if (action.hasError()) {
        Fluttertoast.showToast(
          msg: action.getError(),
          toastLength: Toast.LENGTH_SHORT,
        );
      }
    });
  }

  void startCheckout() {
    if (isCheckout) return;
    isCheckout = true;
    GitRepository repo = envRepo;
    GitAction action = repo.checkout();
    action.control();
    action.setOnComplete(() {
      action.release();
      if (isDisposed) return;
      this.setState(() {
        // if (this.onRefresh != null) this.onRefresh();
        isCheckout = false;
      });
      if (action.hasError()) {
        String err = action.getError();
        Fluttertoast.showToast(
          msg: err,
          toastLength: Toast.LENGTH_SHORT,
        );
      }
    });
  }

  String generateMd5(String input) {
    return md5.convert(utf8.encode(input)).toString();
  }

  Widget icon(Project project) {
    String icon = project?.icon;
    if (icon != null && icon.isNotEmpty) {
      return WebImage(
        url: icon,
        width: 36,
        height: 36,
      );
    }
    if (project?.isValidated == true) {
      String iconPath = project.fullpath + "/icon.png";
      File icon = new File(iconPath);
      if (icon.existsSync()) {
        return Image(
          image: FileImage(icon),
          width: 36,
          height: 36,
        );
      }
    }
    String str = project == null ? "unkown" : generateMd5(project.url);
    return Image(
      image: CachedNetworkImageProvider("https://www.tinygraphs.com/squares/$str?theme=bythepool&numcolors=3&size=180&fmt=jpg"),
      width: 36,
      height: 36,
    );
  }

  List<Widget> buildList(Project project) {
    var lv = envRepo.localID(), hv = envRepo.highID();
//    GitLibrary library = GitLibrary.findLibrary(env_repo);

    return [
      Padding(
        padding: EdgeInsets.only(top: 5, bottom: 5),
        child: Row(
          children: [
            ClipOval(
              child: Container(
                color: Theme.of(context).colorScheme.background,
                child: icon(project),
              ),
              clipper: OvalClipper(),
            ),
            Padding(padding: EdgeInsets.only(left: 8)),
            Text(project.name,
                style: Theme.of(context).textTheme.headline6.copyWith(color: Colors.white)
            )
          ],
        ),
      ),
      Padding(
        padding: EdgeInsets.only(top: 10, bottom: 5),
        child: Text(
          hv == lv ? "${kt("framework")}.$hv" : "${kt("framework")}.$hv ($lv)",
          style: Theme.of(context).textTheme.caption.copyWith(color: Colors.white),
        ),
      ),
      Row(
        children: <Widget>[
          IconButton(
              icon: CircleAvatar(
                  backgroundColor: Theme.of(context).primaryColorLight,
                  child: AnimatedBuilder(
                      animation: controller,
                      child: Icon(Icons.sync, color: Theme.of(context).primaryColor,),
                      builder: (BuildContext context, Widget _widget) {
                        return Transform.rotate(
                          angle: controller.value * -6.3,
                          child: _widget,
                        );
                      }
                  )
              ),
              onPressed: startFetch
          ),
          (lv == hv ? Container(): IconButton(
              icon: CircleAvatar(
                backgroundColor: Theme.of(context).primaryColorLight,
                child: Icon(Icons.get_app, color: Theme.of(context).primaryColor,),
              ),
              onPressed: isCheckout ? null:startCheckout
          ))
        ],
      )
    ];
  }

  List<Widget> getChildren() {
    var project = Project.getMainProject();
    if (envRepo == null || project == null) {
      return [
        Padding(
          padding: EdgeInsets.only(top: 5, bottom: 5),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.max,
            children: [
              ClipOval(
                child: Container(
                  color: Theme.of(context).colorScheme.background,
                  child: Image(
                    image: CachedNetworkImageProvider("https://www.tinygraphs.com/squares/unkown?theme=bythepool&numcolors=3&size=180&fmt=jpg"),
                    fit: BoxFit.contain,
                    width: 36,
                    height: 36,
                  ),
                ),
                clipper: OvalClipper(),
              ),
              Padding(padding: EdgeInsets.only(left: 8)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(kt("no_main_project"),
                      style: Theme.of(context).textTheme.headline6.copyWith(color: Colors.white)
                    ),
                    Padding(padding: EdgeInsets.only(top: 5)),
                    Text(kt("select_main_project_first"),
                      style: Theme.of(context).textTheme.caption.copyWith(color: Colors.white),
                      softWrap: true,
                    )
                  ],
                ),
              )
            ],
          ),
        )
      ];
    } else {
      return buildList(project);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor,
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: getChildren(),
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1000)
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
    isDisposed = true;
  }
}