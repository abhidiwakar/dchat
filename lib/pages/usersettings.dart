import 'dart:io';

import 'package:DChat/constants/const.dart';
import 'package:DChat/helpers/corehelper.dart';
import 'package:DChat/pages/namechangepage.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flare_flutter/flare_actor.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;

class UserSettings extends StatefulWidget {
  @override
  _UserSettingsState createState() => _UserSettingsState();
}

class _UserSettingsState extends State<UserSettings> {
  FToast _fToast;
  bool _isUpdating = false;
  String _currentUserId;
  DocumentReference _collectionReference;
  @override
  void initState() {
    super.initState();
    _currentUserId = FirebaseAuth.instance.currentUser.uid;
    _collectionReference =
        FirebaseFirestore.instance.collection('users').doc(_currentUserId);
    _fToast = FToast();
    _fToast.init(context);
  }

  _updateName(String name, String currentName) async {
    if (name.trim().isNotEmpty) {}
  }

  Widget _buildNameChangeBottomSheet() {
    return SafeArea(
      child: Container(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Change Name',
              style: Theme.of(context).textTheme.headline6,
            ),
            Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: TextField(
                autocorrect: true,
                autofocus: true,
              ),
            ),
          ],
        ),
      ),
    );
  }

  _updateProfilePicture() async {
    PickedFile image =
        await ImagePicker().getImage(source: ImageSource.gallery);
    if (image != null) {
      if (!await CoreHelper().isConnectedToInternet()) {
        CoreHelper().showToast(context, _fToast, NO_INTERNET_STRING,
            titleForIOS: 'Error');
        return;
      }
      File _pickedImage;
      try {
        _pickedImage = File(image.path);

        /* if (mounted) {
          setState(() {
            _isUpdating = true;
          });
        } else {
          return;
        } */
        _isUpdating = true;
        _showWaitingBottomSheet();
        print(_pickedImage.path);
        StorageReference reference = FirebaseStorage.instance
            .ref()
            .child(_currentUserId)
            .child('profile')
            .child(path.basename(_pickedImage.path));
        StorageUploadTask uploadTask = reference.putFile(_pickedImage);
        await uploadTask.onComplete;
        if (uploadTask.isSuccessful) {
          var profilePicUrl =
              await (await uploadTask.onComplete).ref.getDownloadURL();
          await _collectionReference.update({'dp_url': profilePicUrl});
        }
        /* if (mounted) {
          setState(() {
            _isUpdating = false;
          });
        } */
        _isUpdating = false;
        Navigator.pop(context);
        _pickedImage.deleteSync();
      } catch (e) {
        if (await _pickedImage.exists()) {
          _pickedImage.deleteSync();
        }
        _isUpdating = false;
        Navigator.pop(context);
        /* if (mounted) {
          setState(() {
            _isUpdating = false;
          });
        } */
        CoreHelper().showToast(context, _fToast, 'Something went wrong.');
        print(e.toString());
      }
    }
  }

  _switchChangeHandler(
      DocumentReference reference, String key, bool value) async {
    /* setState(() {
      _isUpdating = true;
    }); */
    if (!await CoreHelper().isConnectedToInternet()) {
      CoreHelper().showToast(
        context,
        _fToast,
        NO_INTERNET_STRING,
        titleForIOS: 'Error',
      );
      return;
    }
    await reference.update({
      key: value,
    });
    /* if (mounted) {
      setState(() {
        _isUpdating = false;
      });
    } */
  }

  _showWaitingBottomSheet() {
    showModalBottomSheet(
      isScrollControlled: false,
      enableDrag: false,
      isDismissible: !_isUpdating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(10.0),
          topRight: Radius.circular(10.0),
        ),
      ),
      context: context,
      builder: (_) => WillPopScope(
        onWillPop: () => _isUpdating ? Future.value(false) : Future.value(true),
        child: Container(
          padding: const EdgeInsets.symmetric(
            vertical: 40.0,
          ),
          child: Wrap(
            //crossAxisAlignment: WrapCrossAlignment.center,
            alignment: WrapAlignment.center,
            children: [
              Column(
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
                    height: 15.0,
                  ),
                  Text(
                    'Please Wait...',
                    style: Theme.of(context).textTheme.subtitle2,
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text('Settings'),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        builder: (_, snap) {
          if (snap.connectionState == ConnectionState.active) {
            var dataDoc = snap.data.data();
            return SingleChildScrollView(
              child: Column(
                //crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    children: [
                      dataDoc['dp_url'] != null && dataDoc['dp_url'] != ''
                          ? ClipOval(
                              child: CachedNetworkImage(
                                fit: BoxFit.cover,
                                imageUrl: dataDoc['dp_url'],
                                height: 150.0,
                                width: 150.0,
                                placeholder: (_, __) => Container(
                                  height: 150.0,
                                  width: 150.0,
                                  child: Center(
                                    child: CoreHelper()
                                        .getCircleProgressIndicator(),
                                  ),
                                  color: Colors.grey.shade800,
                                ),
                                errorWidget: (context, url, error) => Container(
                                  height: 150.0,
                                  width: 150.0,
                                  child: Center(
                                    child: Icon(
                                      Icons.error_outline,
                                      color: Colors.red,
                                      size: 48.0,
                                    ),
                                  ),
                                  color: Colors.grey.shade800,
                                ),
                              ),
                            )
                          : Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(150.0),
                                color: Colors.grey.shade800,
                              ),
                              height: 150.0,
                              width: 150.0,
                              child: Icon(
                                Icons.person_outline,
                                size: 80.0,
                              ),
                            ),
                      Positioned(
                        bottom: 0.0,
                        right: 0.0,
                        child: SizedBox(
                          height: 40.0,
                          width: 40.0,
                          child: FloatingActionButton(
                            backgroundColor: Theme.of(context).primaryColor,
                            onPressed: _updateProfilePicture,
                            //onPressed: _showWaitingBottomSheet,
                            heroTag: 'change_dp',
                            child: Icon(
                              Icons.camera_alt,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      )
                    ],
                  ),
                  SizedBox(
                    height: 10.0,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Text(
                      dataDoc['name'],
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context)
                          .textTheme
                          .subtitle1
                          .copyWith(color: Theme.of(context).primaryColor),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Text(
                      dataDoc['email'],
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context)
                          .textTheme
                          .subtitle2
                          .copyWith(color: Colors.white60),
                    ),
                  ),
                  SizedBox(
                    height: 30.0,
                  ),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20.0,
                      vertical: 5.0,
                    ),
                    color: Colors.grey.shade800,
                    child: Text(
                      'Profile settings',
                      style: Theme.of(context).textTheme.subtitle2,
                    ),
                  ),
                  ListTile(
                    title: Text('Change Name'),
                    leading: Icon(Icons.person_outline_rounded),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => NameChangePage(
                          oldName: dataDoc['name'],
                          documentReference: snap.data.reference,
                        ),
                      ),
                    ),
                  ),
                  ListTile(
                    title: Text('Change Password'),
                    leading: Icon(Icons.lock_outline),
                    onTap: () {},
                  ),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20.0,
                      vertical: 5.0,
                    ),
                    color: Colors.grey.shade800,
                    child: Text(
                      'Search result settings',
                      style: Theme.of(context).textTheme.subtitle2,
                    ),
                  ),
                  SwitchListTile(
                    value: dataDoc['can_send_request'],
                    secondary: Icon(Icons.person_add_alt_1_outlined),
                    onChanged: (value) => _switchChangeHandler(
                      snap.data.reference,
                      'can_send_request',
                      value,
                    ),
                    title: Text('Get friend requests'),
                    subtitle: Text(
                      'Allow people to send you friend request. If disabled, people will not see your profile in search result.',
                    ),
                  ),
                  Divider(
                    color: Colors.grey.shade800,
                  ),
                  SwitchListTile(
                    value: dataDoc['hidden_search_dp'],
                    secondary: Icon(Icons.remove_red_eye_outlined),
                    onChanged: (value) => _switchChangeHandler(
                      snap.data.reference,
                      'hidden_search_dp',
                      value,
                    ),
                    title: Text('Hide my DP'),
                    subtitle: Text(
                      'People will not be able to see your display picture when they search for new friends.',
                    ),
                  ),
                  Divider(
                    color: Colors.grey.shade800,
                  ),
                  SwitchListTile(
                    value: dataDoc['hidden_search_email'],
                    secondary: Icon(Icons.email_outlined),
                    onChanged: (value) => _switchChangeHandler(
                      snap.data.reference,
                      'hidden_search_email',
                      value,
                    ),
                    title: Text('Hide my Email'),
                    subtitle: Text(
                      'People will not see your email address when they search for new friends.',
                    ),
                  ),
                ],
              ),
            );
          } else if (snap.connectionState == ConnectionState.waiting) {
            return Center(
              child: Platform.isIOS
                  ? CupertinoActivityIndicator(
                      animating: true,
                    )
                  : CircularProgressIndicator(),
            );
          } else {
            CoreHelper().showToast(
              context,
              _fToast,
              'Something went wrong!',
              titleForIOS: 'Error',
            );
            return Container();
          }
        },
        stream: _collectionReference.snapshots(),
      ),
    );
  }
}
