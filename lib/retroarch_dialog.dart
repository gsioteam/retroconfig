
import 'package:flutter/material.dart';

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
          Text("RetroArch", style: Theme.of(context).textTheme.headline6,),
          Padding(padding: EdgeInsets.only(top: 10)),
          ListTile(
            leading: Icon(Icons.shop, size: 24,),
            title: Text("Google Play"),
            onTap: () {

            },
          ),
          ListTile(
            leading: Icon(Icons.open_in_browser, size: 24,),
            title: Text("Official website"),
            onTap: () {

            },
          ),
          Padding(padding: EdgeInsets.only(top: 10)),
          TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text("Cancel")
          )
        ],
      ),
    );
  }
}