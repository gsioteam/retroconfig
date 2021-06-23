
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:glib/glib.dart';
import 'package:glib/main/context.dart';
import 'package:glib/main/data_item.dart';
import 'package:glib/main/models.dart';
import 'package:glib/main/project.dart';
import 'package:glib/utils/git_repository.dart';
import 'package:retroconfig/pages/details.dart';
import 'package:retroconfig/pages/history.dart';
import 'package:retroconfig/pages/home.dart';
import 'package:path_provider/path_provider.dart' as platform;
import 'package:retroconfig/pages/index.dart';
import 'package:retroconfig/pages/settings.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:retroconfig/utils/history_manager.dart';

import 'configs.dart';
import 'utils/credits_dialog.dart';
import 'utils/download_manager.dart';
import 'utils/progress_items.dart';
import 'widgets/progress_dialog.dart';
import 'localizations/localizations.dart';
import 'pages/libraries.dart';
import 'utils/download_manager.dart';

void main() {
  runApp(MainApp());
}

extension ColorHover on Color {
  Color get hover {
    return Color.fromARGB(this.alpha,
        (this.red * 0.8).round(),
        (this.green * 0.8).round(),
        (this.blue * 0.8).round());
  }
}

class _LifecycleEventHandler extends WidgetsBindingObserver {
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.detached) {
      Glib.destroy();
    }
  }
}

class Splash extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => SplashState();
}

class SplashState extends State<Splash> {
  @override
  Widget build(BuildContext context) {
    return Container();
  }

  Future<void> _loadTemplates() async {
    Future<void> load(String key) async {
      cachedTemplates[key] = await rootBundle.loadString(key);
    }
    await load("assets/roms.xml");
    await load("assets/details.xml");
    // await load("assets/search.xml");
  }

  Future<void> _setup() async {
    await Configs().setup();
    await DownloadManager().setup();
    Directory dir = await platform.getApplicationSupportDirectory();
    await Glib.setup(dir.path);
    Locale locale = PrettyLocalizationsDelegate.supports[KeyValue.get(language_key)];
    if (locale != null) {
      LocaleChangedNotification(locale).dispatch(context);
    }
    await fetchEnv(context);
    WidgetsBinding.instance.addObserver(_LifecycleEventHandler());
    await _loadTemplates();
    await showDisclaimer(context);
  }

  Future<void> showDisclaimer(BuildContext context) async {
    String key = KeyValue.get(disclaimer_key);
    if (key != "true") {
      bool result = await showCreditsDialog(context);
      if (result == true) {
        KeyValue.set(disclaimer_key, "true");
      } else {
        SystemNavigator.pop();
      }
    }
  }

  Future<void> fetchEnv(BuildContext context) async {
    envRepo = GitRepository.allocate("env", env_git_branch);
    if (!envRepo.isOpen()) {
      GitItem item = GitItem.clone(envRepo, env_git_url);
      item.cancelable = false;
      ProgressResult result = await showDialog<ProgressResult>(
          barrierDismissible: false,
          context: context,
          builder: (context) {
            return ProgressDialog(
              title: kt("clone_base_framework"),
              item: item,
            );
          }
      );
      if (result != ProgressResult.Success) {
        throw Exception("WTF?!");
      }
    } else {
    }
  }

  @override
  void initState() {
    super.initState();
    _setup().then((value) {
      Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(
          settings: RouteSettings(name: home_path),
          builder: (BuildContext context) => Home()
      ), (route) => route.isCurrent);
    });
  }
}


class MainApp extends StatefulWidget {

  @override
  State<StatefulWidget> createState() => MainAppState();
}

class MainAppState extends State<MainApp> {

  Locale locale;

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFF191919);
    const Color secondaryColor = Color(0xFF191919);
    const Color backgroundColor = Color(0xFF888888);

    return NotificationListener<LocaleChangedNotification>(
      child: MaterialApp(
        title: 'RetroConfig',
        localizationsDelegates: [
          const PrettyLocalizationsDelegate(),
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        locale: locale,
        supportedLocales: PrettyLocalizationsDelegate.supports.values,
        theme: ThemeData(
          primaryColor: primaryColor,
          backgroundColor: backgroundColor,
          colorScheme: ColorScheme(
            primary: Colors.tealAccent,
            primaryVariant: Colors.white,
            secondary: secondaryColor,
            secondaryVariant: Colors.white,
            surface: backgroundColor,
            background: backgroundColor,
            error: Colors.red,
            onPrimary: primaryColor.hover,
            onSecondary: secondaryColor.hover,
            onSurface: backgroundColor.hover,
            onBackground: backgroundColor.hover,
            onError: Colors.red.shade900,
            brightness: Brightness.dark)
        ),
        home: Splash(),
      ),
      onNotification: (n) {
        setState(() {
          locale = n.locale;
        });
        return true;
      },
    );
  }

  @override
  void initState() {
    super.initState();
    DownloadManager().onClicked = _clickedItem;
  }

  @override
  void dispose() {
    super.dispose();
    DownloadManager().onClicked = null;
  }

  void _clickedItem(DownloadItem downloadItem) {
    for (var item in HistoryManager().items) {
      if (item.item.link == downloadItem.customData) {
        gotoDetails(item);
        break;
      }
    }
  }

  void gotoDetails(HistoryItem historyItem) async {
    DataItem item = historyItem.item;
    Project project = Project.allocate(item.projectKey);
    if (!project.isValidated) {
      Fluttertoast.showToast(msg: kt("no_project_found"));
      project.release();
      return;
    }
    Context ctx = project.createCollectionContext(DETAILS_INDEX, item).control();
    await Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (context) {
      return Details(
          project: project,
          context: ctx
      );
    }), ModalRoute.withName(home_path));
    project.release();
    ctx.release();
  }
}
