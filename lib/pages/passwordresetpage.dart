import 'package:DChat/constants/const.dart';
import 'package:DChat/helpers/corehelper.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flare_flutter/flare_actor.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

class PasswordResetPage extends StatefulWidget {
  @override
  _PasswordResetPageState createState() => _PasswordResetPageState();
}

class _PasswordResetPageState extends State<PasswordResetPage> {
  FocusNode _emailFocusNode = FocusNode();
  TextEditingController _emailController = TextEditingController();
  bool _isSendingPRLink = false;
  FToast _fToast;
  _sendPasswordResetLink() async {
    String email = _emailController.text.trim();
    if (email.isEmpty) {
      CoreHelper().showDefaultActionDialog(
        context,
        'Please enter your email address to continue.',
        title: 'Info',
      );
      _emailFocusNode.requestFocus();
      return;
    }

    if (!CoreHelper().isValidEmail(email)) {
      CoreHelper().showDefaultActionDialog(
        context,
        'Please enter a valid email address to continue.',
        title: 'Info',
      );
      _emailFocusNode.requestFocus();
      return;
    }

    if (!await CoreHelper().isConnectedToInternet()) {
      CoreHelper().showDefaultActionDialog(
        context,
        NO_INTERNET_STRING,
        title: 'Error',
      );
      _emailFocusNode.requestFocus();
      return;
    }

    _emailFocusNode.unfocus();

    setState(() {
      _isSendingPRLink = true;
    });

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      Navigator.pop(context);
      CoreHelper().showToast(
        context,
        _fToast,
        'You\'ll receive an email containing a link to reset your password if your email is valid.',
      );
    } catch (e) {
      _isSendingPRLink = true;
      if (mounted) {
        setState(() {});
      }
      CoreHelper().showDefaultActionDialog(
        context,
        SOMETHING_WENT_WRONG,
        title: 'Error',
      );
      print(e.toString());
    }
  }

  @override
  void initState() {
    super.initState();
    _fToast = FToast();
    _fToast.init(context);
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () =>
          _isSendingPRLink ? Future.value(false) : Future.value(true),
      child: Stack(
        children: [
          Scaffold(
            backgroundColor: Colors.black,
            appBar: AppBar(
              backgroundColor: Colors.black,
              title: Text('Forgot Password'),
              actions: [
                !_isSendingPRLink
                    ? IconButton(
                        icon: Icon(Icons.done),
                        onPressed: _sendPasswordResetLink,
                      )
                    : Container(),
              ],
            ),
            body: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 20.0,
                vertical: 10.0,
              ),
              child: TextField(
                autocorrect: true,
                autofocus: true,
                focusNode: _emailFocusNode,
                controller: _emailController,
                onSubmitted: (_) => _sendPasswordResetLink(),
                decoration: InputDecoration(
                  hintText: 'Tell us your email',
                ),
              ),
            ),
          ),
          _isSendingPRLink
              ? Container(
                  height: MediaQuery.of(context).size.height,
                  width: double.infinity,
                  color: Colors.black45,
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          height: 100,
                          width: 100,
                          child: FlareActor(
                            'assets/animations/waiting.flr',
                            alignment: Alignment.center,
                            color: Theme.of(context).primaryColor,
                            animation: 'Record2',
                            sizeFromArtboard: true,
                          ),
                        ),
                        SizedBox(
                          height: 10.0,
                        ),
                        Text(
                          'Please Wait...',
                          style: Theme.of(context).textTheme.subtitle2,
                        ),
                        Text(
                          'We\'re sending you a password reset link',
                          style: Theme.of(context).textTheme.caption,
                        ),
                      ],
                    ),
                  ),
                )
              : Container(),
        ],
      ),
    );
  }
}
