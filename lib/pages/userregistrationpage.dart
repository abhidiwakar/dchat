import 'package:DChat/constants/const.dart';
import 'package:DChat/helpers/corehelper.dart';
import 'package:DChat/pages/homepage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

class UserRegistrationPage extends StatefulWidget {
  @override
  _UserRegistrationPageState createState() => _UserRegistrationPageState();
}

class _UserRegistrationPageState extends State<UserRegistrationPage> {
  FocusNode _nameFocusNode = FocusNode();
  FocusNode _emailFocusNode = FocusNode();
  FocusNode _passwordFocusNode = FocusNode();
  FocusNode _confirmPasswordFocusNode = FocusNode();

  TextEditingController _nameController = TextEditingController();
  TextEditingController _emailController = TextEditingController();
  TextEditingController _passwordController = TextEditingController();
  TextEditingController _confirmPasswordController = TextEditingController();
  FToast _fToast;
  bool _isAuthentication = false;
  String _nameErrorText = '';
  String _emailErrorText = '';
  String _passwordErrorText = '';
  String _confirmPasswordErrorText = '';

  _registerUser() async {
    String name = _nameController.text.trim();
    String email = _emailController.text.trim();
    String password = _passwordController.text;
    String confirmPassword = _confirmPasswordController.text;

    if (name.isEmpty) {
      _nameErrorText = 'Name is required!';
      setState(() {});
      return;
    } else {
      _nameErrorText = '';
      setState(() {});
    }

    if (email.isEmpty) {
      _emailErrorText = 'Email is required!';
      setState(() {});
      return;
    } else if (!CoreHelper().isValidEmail(email)) {
      _emailErrorText = 'Valid email is required!';
      setState(() {});
      return;
    } else {
      _emailErrorText = '';
      setState(() {});
    }

    if (password.isEmpty) {
      _passwordErrorText = 'Password is required!';
      setState(() {});
      return;
    } else {
      _passwordErrorText = '';
      setState(() {});
    }

    if (confirmPassword.isEmpty) {
      _confirmPasswordErrorText = 'Please confirm your password.';
      setState(() {});
      return;
    } else {
      _confirmPasswordErrorText = '';
      setState(() {});
    }

    if (password != confirmPassword) {
      _confirmPasswordErrorText =
          'Password confirmation doesn\'t match password.';
      setState(() {});
      return;
    } else {
      _confirmPasswordErrorText = '';
      setState(() {});
    }

    if (!await CoreHelper().isConnectedToInternet()) {
      CoreHelper().showDefaultActionDialog(
        context,
        NO_INTERNET_STRING,
        title: 'Error',
      );
      return;
    }

    _nameFocusNode.unfocus();
    _emailFocusNode.unfocus();
    _passwordFocusNode.unfocus();
    _confirmPasswordFocusNode.unfocus();
    _isAuthentication = true;
    setState(() {});

    try {
      User user = (await FirebaseAuth.instance
              .createUserWithEmailAndPassword(email: email, password: password))
          .user;
      if (user != null) {
        FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'can_send_request': true,
          'dp_url': '',
          'email': user.email,
          'hidden_search_dp': false,
          'hidden_search_email': true,
          'id': user.uid,
          'name': name,
        }).then((value) async {
          /* Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(
                builder: (_) => MyHomePage(),
              ),
              (route) => false); */
          user.sendEmailVerification().then((value) {
            Navigator.pop(context);
            CoreHelper().showDefaultActionDialog(
              context,
              'We\'ve sent you a verification email on your given email address. Please follow the link to verify your account.',
              title: 'Registration Successful',
            );
          }).catchError((onError) async {
            print(onError.toString());
            await user.delete();
            _isAuthentication = false;
            if (mounted) {
              setState(() {});
            }
            CoreHelper().showDefaultActionDialog(
              context,
              SOMETHING_WENT_WRONG,
              title: 'Error',
            );
          });
        }).catchError((onError) async {
          print(onError.toString());
          await user.delete();
          _isAuthentication = false;
          if (mounted) {
            setState(() {});
          }
          CoreHelper().showDefaultActionDialog(
            context,
            SOMETHING_WENT_WRONG,
            title: 'Error',
          );
        });
        /* Navigator.pop(context);
        CoreHelper().showToast(
          context,
          _fToast,
          'Registration Successful',
          titleForIOS: 'Success',
          color: Colors.green,
        ); */
      } else {
        _isAuthentication = false;
        if (mounted) {
          setState(() {});
        }
        CoreHelper().showDefaultActionDialog(
          context,
          SOMETHING_WENT_WRONG,
          title: 'Error',
        );
      }
    } on FirebaseAuthException catch (e) {
      _isAuthentication = false;
      if (mounted) {
        setState(() {});
      }
      CoreHelper().showDefaultActionDialog(
        context,
        e.message,
        title: 'Error',
      );
      print(e.toString());
    } catch (e) {
      _isAuthentication = false;
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
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 20.0,
          ),
          child: Stack(
            children: [
              Column(
                children: [
                  Expanded(
                    child: Center(
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'DChat Register',
                              style: Theme.of(context).textTheme.headline6,
                            ),
                            SizedBox(
                              height: 30.0,
                            ),
                            TextField(
                              autocorrect: true,
                              autofocus: true,
                              focusNode: _nameFocusNode,
                              controller: _nameController,
                              onSubmitted: (_) =>
                                  _emailFocusNode.requestFocus(),
                              textInputAction: TextInputAction.next,
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: Colors.grey.shade900,
                                errorText: _nameErrorText.trim().isEmpty
                                    ? null
                                    : _nameErrorText,
                                border: InputBorder.none,
                                hintText: 'Your name',
                                prefixIcon: Icon(Icons.person),
                              ),
                            ),
                            SizedBox(height: 7.0),
                            TextField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              onSubmitted: (_) =>
                                  _passwordFocusNode.requestFocus(),
                              textInputAction: TextInputAction.next,
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: Colors.grey.shade900,
                                errorText: _emailErrorText.trim().isEmpty
                                    ? null
                                    : _emailErrorText,
                                border: InputBorder.none,
                                hintText: 'Your email',
                                prefixIcon: Icon(Icons.email),
                              ),
                            ),
                            SizedBox(height: 7.0),
                            TextField(
                              controller: _passwordController,
                              focusNode: _passwordFocusNode,
                              obscureText: true,
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: Colors.grey.shade900,
                                errorText: _passwordErrorText.trim().isEmpty
                                    ? null
                                    : _passwordErrorText,
                                border: InputBorder.none,
                                hintText: 'Your password',
                                prefixIcon: Icon(Icons.vpn_key),
                              ),
                              textInputAction: TextInputAction.next,
                              onSubmitted: (_) =>
                                  _confirmPasswordFocusNode.requestFocus(),
                            ),
                            SizedBox(height: 7.0),
                            TextField(
                              controller: _confirmPasswordController,
                              focusNode: _confirmPasswordFocusNode,
                              obscureText: true,
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: Colors.grey.shade900,
                                errorText:
                                    _confirmPasswordErrorText.trim().isEmpty
                                        ? null
                                        : _confirmPasswordErrorText,
                                border: InputBorder.none,
                                hintText: 'Confirm password',
                                prefixIcon: Icon(Icons.vpn_key),
                              ),
                              textInputAction: TextInputAction.done,
                              onSubmitted: (_) => _registerUser(),
                            ),
                            SizedBox(height: 7.0),
                            MaterialButton(
                              minWidth: double.infinity,
                              height: 45.0,
                              onPressed:
                                  _isAuthentication ? () {} : _registerUser,
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text('Register'),
                                  ),
                                  _isAuthentication
                                      ? Padding(
                                          padding:
                                              const EdgeInsets.only(right: 8.0),
                                          child: SizedBox(
                                            height: 17,
                                            width: 17,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 3,
                                              valueColor:
                                                  AlwaysStoppedAnimation(
                                                Colors.white,
                                              ),
                                            ),
                                          ),
                                        )
                                      : Icon(Icons.navigate_next),
                                ],
                              ),
                              color: Theme.of(context).primaryColor,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Text(
                    'You agree to all the term and conditions of DChat mobile app by tapping on the (Register) button.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context)
                        .textTheme
                        .caption
                        .copyWith(color: Colors.grey.shade700),
                  ),
                  SizedBox(
                    height: 10.0,
                  ),
                ],
              ),
              SizedBox(
                height: AppBar().preferredSize.height,
                child: AppBar(
                  backgroundColor: Colors.transparent,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
