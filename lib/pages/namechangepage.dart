import 'package:DChat/constants/const.dart';
import 'package:DChat/helpers/corehelper.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flare_flutter/flare_actor.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

class NameChangePage extends StatefulWidget {
  final String oldName;
  final DocumentReference documentReference;

  const NameChangePage(
      {Key key, @required this.oldName, @required this.documentReference})
      : super(key: key);
  @override
  _NameChangePageState createState() => _NameChangePageState();
}

class _NameChangePageState extends State<NameChangePage> {
  TextEditingController _nameController = TextEditingController();
  FToast _fToast;
  bool _isUpdating = false;
  FocusNode _nameFocusNode = FocusNode();

  _changeName() async {
    String newName = _nameController.text.trim();
    if (newName.isNotEmpty) {
      if (!await CoreHelper().isConnectedToInternet()) {
        CoreHelper().showToast(
          context,
          _fToast,
          NO_INTERNET_STRING,
          titleForIOS: 'Error',
        );
        return;
      }

      if (newName == widget.oldName) {
        CoreHelper().showToast(
          context,
          _fToast,
          'Your new name is same as your old name. No changes were made.',
          titleForIOS: 'Info',
        );
        return;
      }

      _nameFocusNode.unfocus();
      if (mounted) {
        setState(() {
          _isUpdating = true;
        });
      }
      try {
        await widget.documentReference.update({'name': newName});
        Navigator.pop(context);
      } catch (e) {
        if (mounted) {
          setState(() {
            _isUpdating = false;
          });
        }
        print(e.toString());
        CoreHelper().showToast(
          context,
          _fToast,
          SOMETHING_WENT_WRONG,
          titleForIOS: 'Error',
        );
      }
    } else {
      CoreHelper().showToast(
        context,
        _fToast,
        'Please enter your new name to continue.',
        titleForIOS: 'Info',
      );
      _nameFocusNode.requestFocus();
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
              title: Text('Change Name'),
              actions: [
                !_isUpdating
                    ? IconButton(
                        icon: Icon(Icons.done),
                        onPressed: _changeName,
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
                focusNode: _nameFocusNode,
                controller: _nameController,
                onSubmitted: (_) => _changeName(),
                decoration: InputDecoration(
                  hintText: 'What\'s your new name?',
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
                          'We\'re updating your name',
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
