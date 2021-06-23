
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:glib/main/models.dart';
import 'package:retroconfig/configs.dart';
import 'package:retroconfig/widgets/settings_list.dart';
import '../localizations/localizations.dart';

class Settings extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => SettingsState();
}

class SettingsState extends State<Settings> {
  @override
  Widget build(BuildContext context) {
    Locale locale = Localizations.localeOf(context);
    String localeValue = "en";
    PrettyLocalizationsDelegate.supports.forEach((key, value) {
      if (locale == value) {
        localeValue = key;
      }
    });
    return SettingsList(
      items: [
        SettingItem(
            SettingItemType.Header,
            kt("general")
        ),
        SettingItem(
            SettingItemType.Options,
            kt("language"),
            value: localeValue,
            data: [
              OptionItem("English", "en"),
              OptionItem("中文(繁體)", "zh-hant"),
              OptionItem("中文(简体)", "zh-hans"),
            ],
            onChange: (value) {
              KeyValue.set(language_key, value);
              LocaleChangedNotification(PrettyLocalizationsDelegate.supports[value]).dispatch(context);
            }
        ),
        SettingItem(
            SettingItemType.Header,
            kt("retroarch")
        ),
        SettingItem(
          SettingItemType.File,
          kt("playlists_directory"),
          data: Configs().retroArchPlaylists,
          onChange: (dir) {
            setState(() {
              Configs().retroArchPlaylists = dir;
            });
          }
        ),
        SettingItem(
          SettingItemType.File,
          kt("thumbnails_directory"),
          data: Configs().retroArchThumbnails,
          onChange: (dir) {
            setState(() {
              Configs().retroArchThumbnails = dir;
            });
          }
        ),
        SettingItem(
          SettingItemType.File,
          kt("roms_directory"),
          data: Configs().romsRoot,
          onChange: (dir) {
            setState(() {
              Configs().romsRoot = dir;
            });
          }
        ),
      ],
    );
  }
}