
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:glib/glib.dart';
import 'package:glib/main/models.dart';
import 'package:glib/utils/git_repository.dart';
import 'package:retroconfig/pages/home.dart';
import 'package:path_provider/path_provider.dart' as platform;
import 'package:retroconfig/pages/index.dart';

import 'configs.dart';
import 'utils/download_manager.dart';
import 'utils/progress_items.dart';
import 'widgets/progress_dialog.dart';
import 'localizations/localizations.dart';
import 'pages/libraries.dart';

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

class Splash extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    _setup(context);
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

  void _setup(BuildContext context) async {
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

    List<DrawerItem> _items = [
      DrawerItem(
        icon: Icon(Icons.apps),
        title: Text("Roms"),
        builder: (context, actionsController) => Index(actionsController),
      ),
      DrawerItem(
        icon: Icon(Icons.extension),
        title: Text("Plugins"),
        actionsController: ActionsController()
          ..actions = [
            ActionItem()
              ..icon = Icon(Icons.add)
              ..key = "add"
          ],
        builder: (context, actionsController) => Libraries(actionsController),
      ),
    ];
    Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(
        builder: (BuildContext context) {
          return Home(
            items: _items
          );
        }
    ), (route) => route.isCurrent);
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
              title: kt(context, ""),
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
        title: 'Flutter Demo',
        localizationsDelegates: [
          const PrettyLocalizationsDelegate(),
        ],
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
}
