
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'localizations/localizations.dart';
import 'package:open_appstore/open_appstore.dart';

class RetroArchDialog extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => RetroArchDialogState();
}

class RetroArchDialogState extends State<RetroArchDialog> {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      padding: EdgeInsets.all(10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(kt("retroarch"), style: Theme.of(context).textTheme.headline6,),
          Padding(padding: EdgeInsets.only(top: 10)),
          ListTile(
            leading: Icon(Icons.shop, size: 24,),
            title: Text(kt("google_play")),
            onTap: () {
              OpenAppstore.launch(
                androidAppId: "com.retroarch"
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.open_in_browser, size: 24,),
            title: Text(kt("official_website")),
            onTap: () {
              launch("https://retroarch.com/?page=platforms");
            },
          ),
          Padding(padding: EdgeInsets.only(top: 10)),
          TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(kt("cancel"))
          )
        ],
      ),
    );
  }
}