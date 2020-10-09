import 'dart:async';

import 'package:DChat/helpers/corehelper.dart';
import 'package:DChat/pages/authentication.dart';
import 'package:DChat/pages/chatpage.dart';
import 'package:DChat/pages/usersettings.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity/connectivity.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  Stream<QuerySnapshot> _collectionStream;
  String _currentUserId;
  bool _shouldShow = false;
  FToast _fToast;

  @override
  void initState() {
    super.initState();
    _fToast = FToast();
    _fToast.init(context);
    _currentUserId = FirebaseAuth.instance.currentUser.uid;
    Connectivity().onConnectivityChanged.listen((event) {
      if (event == ConnectivityResult.mobile ||
          event == ConnectivityResult.wifi) {
        if (_shouldShow) {
          CoreHelper().showToast(
            context,
            _fToast,
            'Connection established! All features are available now.',
            color: Colors.green,
          );
          _shouldShow = true;
        }
      } else {
        _shouldShow = true;
        CoreHelper().showToast(
          context,
          _fToast,
          'Connection lost! Some features might not be available.',
          titleForIOS: 'Internet Issue',
        );
      }
    });
    _collectionStream = FirebaseFirestore.instance
        .collection('chats')
        .where('members', arrayContains: _currentUserId)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(widget.title),
        actions: [
          PopupMenuButton(
            onSelected: (value) {
              switch (value) {
                case 'settings':
                  //print('Settings under development');
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => UserSettings(),
                    ),
                  );
                  break;
                case 'logout':
                  FirebaseAuth.instance.signOut();
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => Authentication(),
                    ),
                  );
                  break;
                default:
                  print('No option selected');
              }
            },
            itemBuilder: (context) {
              return <PopupMenuItem>[
                PopupMenuItem(
                  value: 'new_friend',
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.person),
                      SizedBox(
                        width: 10.0,
                      ),
                      Text('New Friends'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'new_chat',
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.chat),
                      SizedBox(
                        width: 10.0,
                      ),
                      Text('New Chat'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'settings',
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.settings),
                      SizedBox(
                        width: 10.0,
                      ),
                      Text('Settings'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'logout',
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.logout),
                      SizedBox(
                        width: 10.0,
                      ),
                      Text('Logout'),
                    ],
                  ),
                ),
              ];
            },
          )
        ],
      ),
      body: Container(
        child: StreamBuilder<QuerySnapshot>(
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.active) {
              if (snapshot.hasData) {
                if (snapshot.data.docs != null &&
                    snapshot.data.docs.length > 0) {
                  return ListView.builder(
                    itemBuilder: (context, index) {
                      var doc = snapshot.data.docs[index];
                      var members = doc.get('members') as List<dynamic>;
                      members.remove(_currentUserId);
                      var chatsStream = snapshot.data.docs[0].reference
                          .collection('chats')
                          .orderBy('time')
                          .snapshots();
                      //_activeStreams.add(chatsStream);
                      if (doc.get('type') == 'single') {
                        return StreamBuilder<dynamic>(
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.active) {
                              return ListTile(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => ChatPage(
                                        members[0],
                                        _currentUserId,
                                        doc.id,
                                        initialName: snapshot.data.get('name'),
                                        initialDpUrl:
                                            snapshot.data.get('dp_url'),
                                      ),
                                    ),
                                  );
                                },
                                leading: ClipOval(
                                  child: CachedNetworkImage(
                                    imageUrl: snapshot.data.get('dp_url'),
                                    height: 40.0,
                                    width: 40.0,
                                  ),
                                ),
                                title: Text(snapshot.data.get('name')),
                                subtitle: StreamBuilder<QuerySnapshot>(
                                  builder: (context, snapshot) {
                                    if (snapshot.connectionState ==
                                        ConnectionState.active) {
                                      if (snapshot.hasData) {
                                        if (snapshot.data.docs != null &&
                                            snapshot.data.docs.length > 0) {
                                          var lastChatDoc = snapshot.data.docs[
                                              snapshot.data.docs.length - 1];
                                          var readyby =
                                              lastChatDoc.data()['ready_by']
                                                  as List<dynamic>;
                                          if (lastChatDoc.get('type') ==
                                              'message') {
                                            return Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Flexible(
                                                  child: Text(
                                                    lastChatDoc.get('sender') ==
                                                            _currentUserId
                                                        ? 'You: ' +
                                                            lastChatDoc
                                                                .get('message')
                                                        : lastChatDoc
                                                            .get('message'),
                                                  ),
                                                ),
                                                lastChatDoc.get('sender') ==
                                                        _currentUserId
                                                    ? Container()
                                                    : readyby != null &&
                                                            readyby.contains(
                                                                _currentUserId)
                                                        ? Container()
                                                        : Container(
                                                            margin:
                                                                const EdgeInsets
                                                                    .only(
                                                              left: 20.0,
                                                            ),
                                                            height: 10.0,
                                                            width: 10.0,
                                                            decoration:
                                                                BoxDecoration(
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                10.0,
                                                              ),
                                                              color: Colors.red,
                                                            ),
                                                          ),
                                              ],
                                            );
                                          } else {
                                            return Container();
                                          }
                                        } else {
                                          return Container();
                                        }
                                      } else {
                                        return Container();
                                      }
                                    } else {
                                      return Container();
                                    }
                                  },
                                  stream: chatsStream,
                                ),
                              );
                            } else {
                              return Container();
                            }
                          },
                          stream: FirebaseFirestore.instance
                              .collection('users')
                              .doc(members[0])
                              .snapshots(),
                        );
                      } else {
                        return ListTile(
                          title: Text(
                            doc.get('title'),
                          ),
                        );
                      }
                    },
                    itemCount: snapshot.data.docs.length,
                  );
                } else {
                  var randomQuote = CoreHelper().loadRandomQuote();
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            randomQuote['quote'],
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(
                            height: 10.0,
                          ),
                          Text(
                            "- ${randomQuote['author']}",
                            textAlign: TextAlign.right,
                            style: Theme.of(context).textTheme.caption,
                          ),
                        ],
                      ),
                    ),
                  );
                }
              } else {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.warning,
                        color: Colors.yellow.shade700,
                      ),
                      SizedBox(
                        height: 10.0,
                      ),
                      Text(
                        'Something went wrong!',
                        style: Theme.of(context).textTheme.subtitle2,
                      ),
                    ],
                  ),
                );
              }
            } else if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(
                child: SizedBox(
                  height: 25.0,
                  width: 25.0,
                  child: CircularProgressIndicator(
                    strokeWidth: 3.0,
                    valueColor: AlwaysStoppedAnimation(Colors.white),
                  ),
                ),
              );
            } else {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.warning,
                      color: Colors.yellow.shade700,
                    ),
                    SizedBox(
                      height: 10.0,
                    ),
                    Text(
                      'Something went wrong!',
                      style: Theme.of(context).textTheme.subtitle2,
                    ),
                  ],
                ),
              );
            }
          },
          stream: _collectionStream,
        ),
      ),
    );
  }
}
