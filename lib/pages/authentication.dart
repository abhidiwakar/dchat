import 'package:DChat/constants/const.dart';
import 'package:DChat/helpers/corehelper.dart';
import 'package:DChat/pages/homepage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

class Authentication extends StatefulWidget {
  @override
  _AuthenticationState createState() => _AuthenticationState();
}

class _AuthenticationState extends State<Authentication> {
  TextEditingController _emailController = TextEditingController();
  TextEditingController _passwordController = TextEditingController();
  FocusNode _passwordFocusNode = FocusNode();
  FToast _fToast;
  bool _isAuthentication = false;
  String _emailErrorText = '';
  String _passwordErrorText = '';

  _authenticateUser() async {
    String email = _emailController.text.trim();
    String password = _passwordController.text.trim();

    if (email.isEmpty) {
      //CoreHelper().showToast(_fToast, 'Email is required!');
      _emailErrorText = 'Email is required!';
      setState(() {});
      return;
    } else if (!CoreHelper().isValidEmail(email)) {
      //CoreHelper().showToast(_fToast, 'Valid email is required!');
      _emailErrorText = 'Valid email is required!';
      setState(() {});
      return;
    } else {
      _emailErrorText = '';
      setState(() {});
    }
    if (password.isEmpty) {
      //CoreHelper().showToast(_fToast, 'Password is required!');
      _passwordErrorText = 'Password is required!';
      setState(() {});
      return;
    } else {
      _passwordErrorText = '';
      setState(() {});
    }

    if (_passwordFocusNode.hasFocus) {
      _passwordFocusNode.unfocus();
    }

    _isAuthentication = true;
    setState(() {});

    if (!await CoreHelper().isConnectedToInternet()) {
      _isAuthentication = false;
      if (mounted) {
        setState(() {});
      }
      CoreHelper().showDefaultActionDialog(
        context,
        NO_INTERNET_STRING,
        title: 'Error',
      );
      return;
    }

    try {
      var authResult = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);
      User user = authResult.user;
      if (user != null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => MyHomePage(
              title: 'DChat',
            ),
          ),
        );
      } else {
        CoreHelper().showToast(context, _fToast, SOMETHING_WENT_WRONG,
            titleForIOS: 'Error');
        _isAuthentication = false;
        if (mounted) {
          setState(() {});
        }
      }
    } on FirebaseAuthException {
      CoreHelper().showToast(context, _fToast,
          'Invalid username or password! Please try agin with correct details.',
          titleForIOS: 'Error');
      _isAuthentication = false;
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      print(e.toString());
      CoreHelper().showToast(context, _fToast,
          'Something went wrong! Please try again in a minute or two.',
          titleForIOS: 'Error');
      _isAuthentication = false;
      if (mounted) {
        setState(() {});
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _fToast = FToast();
    _fToast.init(context);
  }

  @override
  void dispose() {
    _emailController?.dispose();
    _passwordController?.dispose();
    _passwordFocusNode?.dispose();
    super.dispose();
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
          child: Column(
            children: [
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ClipOval(
                          child: Container(
                            color: Colors.white,
                            child: Image.asset(
                              'assets/images/d_chat_logo.png',
                              height: 120,
                              width: 120,
                            ),
                          ),
                        ),
                        SizedBox(
                          height: 10.0,
                        ),
                        Text(
                          'DChat',
                          style: Theme.of(context).textTheme.headline6,
                        ),
                        SizedBox(
                          height: 30.0,
                        ),
                        TextField(
                          toolbarOptions: ToolbarOptions(
                            paste: false,
                            copy: false,
                            cut: false,
                            selectAll: false,
                          ),
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          onSubmitted: (_) => _passwordFocusNode.requestFocus(),
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
                          toolbarOptions: ToolbarOptions(
                            paste: false,
                            copy: false,
                            cut: false,
                            selectAll: false,
                          ),
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
                        ),
                        SizedBox(height: 7.0),
                        MaterialButton(
                          minWidth: double.infinity,
                          // shape: RoundedRectangleBorder(
                          //   borderRadius: BorderRadius.circular(
                          //     10.0,
                          //   ),
                          // ),
                          height: 45.0,
                          onPressed: _authenticateUser,
                          child: Row(
                            children: [
                              Expanded(
                                child: Text('Login'),
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
                                          valueColor: AlwaysStoppedAnimation(
                                              Colors.white),
                                        ),
                                      ),
                                    )
                                  : Icon(Icons.navigate_next),
                            ],
                          ),
                          color: Theme.of(context).primaryColor,
                        )
                      ],
                    ),
                  ),
                ),
              ),
              Text(
                'You agree to all the term and conditions of DChat mobile app by tapping on the (Login) button.',
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
        ),
      ),
    );
  }
}
