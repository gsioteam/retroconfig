import 'package:app_launcher/app_launcher.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import '../localizations/localizations.dart';
import '../retroarch_dialog.dart';

const List<String> retroarch_packages = [
  "com.retroarch",
  "com.retroarch.aarch64",
  "com.retroarch.ra32"
];

bool _wait = false;
void openRetroArch(BuildContext context) async {
  if (_wait) return;
  _wait = true;
  var kt = lc(context);
  for (var packageName in retroarch_packages) {
    try {
      if (await AppLauncher.hasApp(androidApplicationId: packageName)) {
        var result = await showDialog<bool>(
            context: context,
            builder: (context) {
              return AlertDialog(
                title: Text(kt("open_retroarch")),
                content: Text(kt("found_retroarch").replaceFirst("{0}", packageName)),
                actions: [
                  TextButton(
                    child: Text(kt("yes")),
                    onPressed: () {
                      Navigator.of(context).pop(true);
                    },
                  ),
                  TextButton(
                    child: Text(kt("no")),
                    onPressed: () {
                      Navigator.of(context).pop(false);
                    },
                  )
                ],
              );
            }
        );
        if (result == true) {
          AppLauncher.openApp(androidApplicationId: packageName);
          _wait = false;
          return;
        }
      }
    } catch (e) {

    }
  }
  await showDialog(context: context, builder: (context) {
    return Dialog(
      child: RetroArchDialog(),
    );
  });
  _wait = false;
}