import 'package:DChat/constants/const.dart';
import 'package:DChat/helpers/corehelper.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flare_flutter/flare_actor.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

class ChangePasswordPage extends StatefulWidget {
  final DocumentReference documentReference;

  const ChangePasswordPage({Key key, @required this.documentReference})
      : super(key: key);
  @override
  _ChangePasswordPageState createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  TextEditingController _oldPassController = TextEditingController();
  TextEditingController _newPassController = TextEditingController();
  TextEditingController _newConfirmPassController = TextEditingController();

  FToast _fToast;
  bool _isUpdating = false;
  FocusNode _oldPassFocusNode = FocusNode();
  FocusNode _newPassFocusNode = FocusNode();
  FocusNode _newConfirmPassFocusNode = FocusNode();

  _changePassword() async {
    String oldPass = _oldPassController.text;
    String newPass = _newPassController.text;
    String newConfirmPass = _newConfirmPassController.text;

    if (oldPass.trim().isEmpty) {
      /* CoreHelper().showToast(
        context,
        _fToast,
        'Please enter your current password to continue.',
        titleForIOS: 'Info',
      ); */
      CoreHelper().showDefaultActionDialog(
        context,
        'Please enter your current password to continue.',
        title: 'Info',
      );
      _oldPassFocusNode.requestFocus();
      return;
    }

    if (newPass.trim().isEmpty) {
      CoreHelper().showDefaultActionDialog(
        context,
        'Please enter new password to continue.',
        title: 'Info',
      );
      /* CoreHelper().showToast(
        context,
        _fToast,
        'Please enter new password to continue.',
        titleForIOS: 'Info',
      ); */
      _newPassFocusNode.requestFocus();
      return;
    }

    if (newConfirmPass.trim().isEmpty) {
      CoreHelper().showDefaultActionDialog(
        context,
        'Please confirm your new password to continue.',
        title: 'Info',
      );
      /* CoreHelper().showToast(
        context,
        _fToast,
        'Please confirm your new password to continue.',
        titleForIOS: 'Info',
      ); */
      _newConfirmPassFocusNode.requestFocus();
      return;
    }

    if (newPass.trim() != newConfirmPass.trim()) {
      CoreHelper().showDefaultActionDialog(
        context,
        'Password confirmation doesn\'t match the password',
        title: 'Error',
      );
      /* CoreHelper().showToast(
        context,
        _fToast,
        'Password confirmation doesn\'t match the password',
        titleForIOS: 'Error',
      ); */
      _newConfirmPassFocusNode.requestFocus();
      return;
    }

    if (newPass.trim() == oldPass.trim()) {
      CoreHelper().showDefaultActionDialog(
        context,
        'Old password and new password are same. No changes were made.',
        title: 'Error',
      );
      _newPassFocusNode.requestFocus();
      return;
    }

    if (!await CoreHelper().isConnectedToInternet()) {
      CoreHelper().showDefaultActionDialog(
        context,
        NO_INTERNET_STRING,
        title: 'Error',
      );
      return;
    }

    _oldPassFocusNode.unfocus();
    _newPassFocusNode.unfocus();
    _newConfirmPassFocusNode.unfocus();

    if (mounted) {
      setState(() {
        _isUpdating = true;
      });
    }

    var authInstance = FirebaseAuth.instance;
    try {
      await authInstance.signInWithEmailAndPassword(
          email: authInstance.currentUser.email, password: oldPass);
      await FirebaseAuth.instance.currentUser.updatePassword(newPass);
      Navigator.pop(context);
      CoreHelper().showToast(
        context,
        _fToast,
        'Changed password successfully.',
        color: Colors.green,
        titleForIOS: 'Success',
      );
    } on FirebaseAuthException catch (firebaseException) {
      if (mounted) {
        setState(() {
          _isUpdating = false;
        });
      }
      print(firebaseException.toString());

      CoreHelper().showDefaultActionDialog(
        context,
        firebaseException.code == 'wrong-password'
            ? 'Invalid old password. Please try again.'
            : firebaseException.message,
        title: 'Error',
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _isUpdating = false;
        });
      }
      print(e.toString());
      CoreHelper().showDefaultActionDialog(
        context,
        SOMETHING_WENT_WRONG,
        title: 'Error',
      );
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
      onWillPop: () => _isUpdating ? Future.value(false) : Future.value(true),
      child: Stack(
        children: [
          Scaffold(
            backgroundColor: Colors.black,
            appBar: AppBar(
              backgroundColor: Colors.black,
              title: Text('Change Password'),
              actions: [
                !_isUpdating
                    ? IconButton(
                        icon: Icon(Icons.done),
                        onPressed: _changePassword,
                      )
                    : Container(),
              ],
            ),
            body: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 20.0,
                vertical: 10.0,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      autofocus: true,
                      obscureText: true,
                      focusNode: _oldPassFocusNode,
                      controller: _oldPassController,
                      onSubmitted: (_) => _newPassFocusNode.requestFocus(),
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        hintText: 'Your current password',
                      ),
                    ),
                    TextField(
                      focusNode: _newPassFocusNode,
                      obscureText: true,
                      controller: _newPassController,
                      onSubmitted: (_) =>
                          _newConfirmPassFocusNode.requestFocus(),
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        hintText: 'New password',
                      ),
                    ),
                    TextField(
                      obscureText: true,
                      focusNode: _newConfirmPassFocusNode,
                      controller: _newConfirmPassController,
                      onSubmitted: (_) => _changePassword(),
                      decoration: InputDecoration(
                        hintText: 'Confirm new password',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          _isUpdating
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
                          'We\'re updating your password',
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
