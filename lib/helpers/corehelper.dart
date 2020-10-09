import 'dart:io';
import 'dart:math';

import 'package:DChat/widgets/toast.dart';
import 'package:connectivity/connectivity.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

class CoreHelper {
  showToast(
    BuildContext context,
    FToast fToast,
    String message, {
    String titleForIOS = 'Info',
    Color color = Colors.red,
    int duration = 3,
    ToastGravity gravity = ToastGravity.TOP,
  }) {
    if (Platform.isIOS) {
      showDefaultActionDialog(context, message, title: titleForIOS);
    } else {
      fToast.showToast(
        child: ToastWidget(
          data: message,
          color: color,
        ),
        gravity: gravity,
        toastDuration: Duration(seconds: duration),
      );
    }
  }

  Map<String, String> loadRandomQuote() {
    List<Map<String, String>> quotesList = [
      {
        'quote':
            '“Be who you are and say what you feel, because those who mind don\'t matter, and those who matter don\'t mind.”',
        'author': 'Bernard M. Baruch'
      },
      {
        'quote':
            '“You know you\'re in love when you can\'t fall asleep because reality is finally better than your dreams.”',
        'author': 'Dr. Seuss'
      },
      {
        'quote':
            '“You only live once, but if you do it right, once is enough.”',
        'author': 'Mae West'
      },
      {
        'quote': '“Be the change that you wish to see in the world.”',
        'author': 'Mahatma Gandhi'
      },
      {
        'quote':
            '“In three words I can sum up everything I\'ve learned about life: it goes on.”',
        'author': 'Robert Frost'
      },
      {
        'quote':
            '“If you want to know what a man\'s like, take a good look at how he treats his inferiors, not his equals.”',
        'author': 'J.K. Rowling'
      }
    ];
    return quotesList[Random().nextInt(quotesList.length)];
  }

  isConnectedToInternet() async {
    var result = await Connectivity().checkConnectivity();
    if (result == ConnectivityResult.mobile ||
        result == ConnectivityResult.wifi) {
      return true;
    } else {
      return false;
    }
  }

  Widget getCircleProgressIndicator() {
    if (Platform.isIOS) {
      return CupertinoActivityIndicator(
        animating: true,
      );
    } else {
      return CircularProgressIndicator();
    }
  }

  showDefaultActionDialog(BuildContext context, String message,
      {String title = 'Info'}) {
    if (Platform.isIOS) {
      showCupertinoDialog(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            CupertinoDialogAction(
              child: Text('Ok'),
              isDefaultAction: true,
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      );
    } else {
      showDialog(
        context: context,
        child: AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            FlatButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Ok'),
            ),
          ],
        ),
      );
    }
  }

  bool isValidEmail(String email) {
    RegExp regExp = RegExp(
        r"^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,253}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,253}[a-zA-Z0-9])?)*$");
    return regExp.hasMatch(email);
  }
}
