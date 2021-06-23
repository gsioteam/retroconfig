
import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:glib/core/array.dart';
import 'package:glib/main/context.dart';
import 'package:glib/main/models.dart';
import 'package:glib/main/project.dart';
import 'package:glib/utils/bit64.dart';
import 'package:glib/utils/git_repository.dart';
import 'package:retroconfig/pages/home.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:crypto/crypto.dart';
import 'package:retroconfig/widgets/web_image.dart';

import '../localizations/localizations.dart';
import '../widgets/better_refresh_indicator.dart';
import '../widgets/spin_item.dart';
import '../widgets/progress_dialog.dart';
import '../utils/progress_items.dart';

const LibURL = "https://api.github.com/repos/gsioteam/glib_env/issues/1/comments?per_page={1}&page={0}";
const int per_page = 40;

String generateMd5(String input) {
  return md5.convert(utf8.encode(input)).toString();
}

class LibraryNotification extends Notification {
}

class LibraryCell extends StatefulWidget {

  final GitLibrary library;

  LibraryCell({Key key, this.library}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _LibraryCellState(library);
  }
}

class _LibraryCellState extends State<LibraryCell> {

  GitLibrary library;
  GitRepository repo;
  Project project;
  String dirName;
  GlobalKey<SpinItemState> _spinKey = GlobalKey();

  _LibraryCellState(this.library) {
    library.control();
    String name = Bit64.encodeString(library.url);
    project = Project.allocate(name);
    dirName = name;
    repo = GitRepository.allocate(name);
  }

  @override
  void dispose() {
    library.release();
    project.release();
    super.dispose();
  }

  String getIcon() {
    String icon = library.icon;
    if (icon != null && icon.isNotEmpty) {
      return icon;
    }
    if (project.isValidated) {
      String iconpath = project.fullpath + "/icon.png";
      File icon = new File(iconpath);
      if (icon.existsSync()) {
        return iconpath;
      } else if (project.icon.isNotEmpty) {
        return project.icon;
      }
    }
    return "http://tinygraphs.com/squares/${generateMd5(library.url)}?theme=bythepool&numcolors=3&size=180&fmt=jpg";
  }

  void installConfirm() {
    showDialog(
        context: context,
        builder: (context) {
          var kt = lc(context);
          return AlertDialog(
            title: Text(kt("confirm")),
            content: Text(
              kt("install_confirm").replaceFirst("{url}", library.url),
              softWrap: true,
            ),
            actions: <Widget>[
              TextButton(
                  onPressed: (){
                    Navigator.of(context).pop(true);
                    install();
                  },
                  child: Text(kt("yes"))
              ),
              TextButton(
                  onPressed: (){
                    Navigator.of(context).pop(false);
                  },
                  child: Text(kt("no"))
              ),
            ],
          );
        }
    );
  }

  void install() {
    showDialog(
        barrierDismissible: false,
        context: context,
        builder: (context) {
          return ProgressDialog(
            title: kt("clone_project"),
            item: GitItem.clone(repo, library.url)..cancelable=true,
          );
        }
    ).then((value) {
      setState(() {
        project?.release();
        project = Project.allocate(dirName);
        print("install complete ${repo.isOpen()} ${project.isValidated} $dirName");
        if (repo.isOpen() && project.isValidated)
          selectConfirm();
      });
    });
  }

  void selectMainProject() {
    project.setMainProject();
    Fluttertoast.showToast(
      msg: kt("after_select_main").replaceFirst("{0}", project.name),
      toastLength: Toast.LENGTH_LONG,
    );
  }

  void selectConfirm() {
    BuildContext mainContext = context;
    showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text(kt("confirm")),
            content: Text(kt("select_main_project")),
            actions: <Widget>[
              TextButton(
                  onPressed: (){
                    Navigator.of(context).pop();
                    selectMainProject();
                    LibraryNotification().dispatch(mainContext);
                  },
                  child: Text(kt("yes"))
              ),
              TextButton(
                  onPressed: (){
                    Navigator.of(context).pop();
                  },
                  child: Text(kt("no"))
              ),
            ],
          );
        }
    );
  }

  Widget buildUnkown(BuildContext context) {
    String title = library.title;
    if (title == null || title.isEmpty) title = library.url;
    return ListTile(
      contentPadding: EdgeInsets.fromLTRB(16, 6, 10, 6),
      title: Text(title,),
      subtitle: Text(kt("not_installed")),
      leading: Container(
        child: WebImage(
          url: getIcon(),
          width: 56,
          height: 56,
        ),
        decoration: BoxDecoration(
            color: Color(0x1F999999),
            borderRadius: BorderRadius.all(Radius.circular(4))
        ),
      ),
      onTap: installConfirm,
    );
  }

  Widget buildProject(BuildContext context) {
    List<InlineSpan> icons = [
      TextSpan(text: project.name),
    ];
    if (project.path == KeyValue.get("MAIN_PROJECT")) {
      icons.insert(0, WidgetSpan(child: Icon(Icons.arrow_right, color: Theme.of(context).colorScheme.primary,)));
    }
    return ListTile(
      contentPadding: EdgeInsets.fromLTRB(16, 6, 10, 6),
      title: Text.rich(TextSpan(
          children: icons
      )),
      subtitle: Text("Ver. ${repo.localID()}"),
      leading: Container(
        child: WebImage(
          url: getIcon(),
          width: 56,
          height: 56,
        ),
        decoration: BoxDecoration(
            color: Color(0x1F999999),
            borderRadius: BorderRadius.all(Radius.circular(4))
        ),
      ),
      trailing: IconButton(
        icon: SpinItem(
          child: Icon(Icons.sync, color: Theme.of(context).colorScheme.primary,),
          key: _spinKey,
        ),
        onPressed: (){
          if (_spinKey.currentState == null || _spinKey.currentState.isLoading) return;
          _spinKey.currentState?.startAnimation();
          GitAction action = repo.fetch();
          action.control();
          action.setOnComplete(() {
            action.release();
            if (action.hasError()) {
              Fluttertoast.showToast(msg: action.getError(), toastLength: Toast.LENGTH_LONG);
              _spinKey.currentState?.stopAnimation();
              return;
            }
            if (repo.localID() != repo.highID()) {
              GitAction action = repo.checkout().control();
              action.setOnComplete(() {
                action.release();
                if (action.hasError()) {
                  Fluttertoast.showToast(msg: action.getError(), toastLength: Toast.LENGTH_LONG);
                }
                _spinKey.currentState?.stopAnimation();
                setState(() { });
              });
            } else {
              _spinKey.currentState?.stopAnimation();
              setState(() { });
            }
          });
        },
      ),
      onTap: selectConfirm,
    );
  }

  @override
  Widget build(BuildContext context) {
    return (repo.isOpen() && project.isValidated) ? buildProject(context) : buildUnkown(context);
  }

}

class Libraries extends StatefulWidget {

  final ActionsController controller;

  Libraries(this.controller);

  @override
  State<StatefulWidget> createState() => LibrariesState();
}

class LibrariesState extends State<Libraries> {
  Array data;
  LibraryContext libraryContext;
  bool hasMore = false;
  BetterRefreshIndicatorController _controller;
  int pageIndex = 0;
  static DateTime lastUpdateTime;

  Future<bool> requestPage(int page) async {
    String url = LibURL.replaceAll("{0}", page.toString()).replaceAll("{1}", per_page.toString());
    http.Request request = http.Request("GET", Uri.parse(url));
    request.headers["Accept"] = "application/vnd.github.v3+json";
    http.StreamedResponse res = await request.send();
    String result = await res.stream.bytesToString();
    List<dynamic> json = jsonDecode(result);
    bool needLoad = false;

    for (int i = 0, t = json.length; i < t; ++i) {
      Map<String, dynamic> item = json[i];
      String body = item["body"];
      if (body != null) {
        if (libraryContext.parseLibrary(body)) {
          needLoad = true;
        }
      }
    }
    hasMore = json.length >= per_page;
    pageIndex = page;
    return needLoad;
  }

  void reload() async {
    int page = 0;
    _controller.startLoading();
    try {
      if (await requestPage(page)) {
        lastUpdateTime = DateTime.now();
        setState(() {});
      }
    } catch (e) {
    }
    _controller.stopLoading();
  }

  bool onRefresh() {
    reload();
    return true;
  }

  void loadMore() async {
    int page = pageIndex + 1;
    _controller.startLoading();
    try {
      if (await requestPage(page)) setState(() {});
    } catch (e) {
    }
    _controller.stopLoading();
  }

  @override
  Widget build(BuildContext context) {
    var project = Project.getMainProject();
    bool hasProject = project != null;

    return NotificationListener<LibraryNotification>(
      child: BetterRefreshIndicator(
        child: ListView.separated(
          itemBuilder: (context, idx) {
            if (!hasProject) {
              if (idx == 0) {
                return Container(
                  color: Theme.of(context).colorScheme.background,
                  padding: EdgeInsets.all(10),
                  child: Text(
                    kt("libraries_hint"),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyText1.copyWith(
                        color: Theme.of(context).colorScheme.primaryVariant
                    ),
                  ),
                );
              } else {
                --idx;
              }
            }

            GitLibrary library = data[idx];
            String token = library.token;
            if (token.isEmpty) {
              String url = library.url;
              return Dismissible(
                key: GlobalObjectKey(url),
                background: Container(color: Colors.red,),
                child: LibraryCell(
                  library: library,
                ),
                confirmDismiss: (_) async {
                  bool result = await showDialog<bool>(
                      context: context,
                      builder: (context) {
                        return AlertDialog(
                          title: Text(kt("remove_project")),
                          content: Text(kt("would_remove_project").replaceFirst("{0}", url)),
                          actions: [
                            TextButton(
                                onPressed: (){
                                  Navigator.of(context).pop(true);
                                },
                                child: Text(kt("yes"))
                            ),
                            TextButton(
                                onPressed: (){
                                  Navigator.of(context).pop(false);
                                },
                                child: Text(kt("no"))
                            ),
                          ],
                        );
                      }
                  );
                  return result == true;
                },
                onDismissed: (_) {
                  setState(() {
                    libraryContext.removeLibrary(url);
                  });
                },
              );
            } else {
              return LibraryCell(
                key: GlobalObjectKey(token),
                library: library,
              );
            }
          },
          separatorBuilder: (context, idx) {
            return Divider(height: 1,);
          },
          itemCount: hasProject ? data.length : data.length + 1,
        ),
        controller: _controller,
      ),
      onNotification: (notification) {
        setState(() { });
        return false;
      },
    );
  }

  @override
  void initState() {
    super.initState();
    widget.controller.onClicked = _actionClicked;
    _controller = BetterRefreshIndicatorController();
    _controller.onRefresh = onRefresh;
    _controller.onLoadMore = loadMore;
    libraryContext = LibraryContext.allocate();
    data = libraryContext.data.control();
    if (lastUpdateTime == null ||
        lastUpdateTime
            .add(Duration(minutes: 5))
            .isBefore(DateTime.now()))
      reload();
  }

  @override
  void dispose() {
    data.release();
    libraryContext.release();
    super.dispose();
    widget.controller.onClicked = null;
    _controller.onRefresh = null;
    _controller.onLoadMore = null;
  }

  bool _wait = false;
  void _actionClicked(String key) async {
    if (_wait) return;
    TextEditingController controller = TextEditingController();
    String url = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(kt("new_project")),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(
                hintText: kt("new_project_hint")
            ),
          ),
          actions: <Widget>[
            TextButton(
                onPressed: (){
                  Navigator.of(context).pop(controller.text);
                },
                child: Text(kt("add"))
            )
          ],
        );
      },
    );
    controller.dispose();
    _wait = false;
    if (url != null) {
      setState(() {
        libraryContext.insertLibrary(url);
      });
    }
  }
}