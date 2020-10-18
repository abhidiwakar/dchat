import 'package:DChat/helpers/corehelper.dart';
import 'package:DChat/pages/findnewfriends.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_icons/flutter_icons.dart';

class NewFriendsPage extends StatefulWidget {
  @override
  _NewFriendsPageState createState() => _NewFriendsPageState();
}

class _NewFriendsPageState extends State<NewFriendsPage>
    with SingleTickerProviderStateMixin {
  CollectionReference _collectionReference;
  TabController _tabController;

  _deleteRequest(String opid, {bool oposite = false}) async {
    await _collectionReference.doc(opid).update(
      {
        oposite ? 'sent_request' : 'received_request':
            FieldValue.arrayRemove([FirebaseAuth.instance.currentUser.uid])
      },
    );
    await _collectionReference
        .doc(FirebaseAuth.instance.currentUser.uid)
        .update(
      {
        oposite ? 'received_request' : 'sent_request':
            FieldValue.arrayRemove([opid])
      },
    );
    CoreHelper().showDefaultActionDialog(
      context,
      oposite ? 'Friend request rejected' : 'Friend request deleted.',
    );
  }

  _acceptRequest(String opid) async {
    await _collectionReference.doc(opid).update({
      'connections': FieldValue.arrayUnion(
        [
          FirebaseAuth.instance.currentUser.uid,
        ],
      ),
      'sent_request': FieldValue.arrayRemove(
        [
          FirebaseAuth.instance.currentUser.uid,
        ],
      ),
    });
    await _collectionReference
        .doc(FirebaseAuth.instance.currentUser.uid)
        .update({
      'connections': FieldValue.arrayUnion(
        [
          opid,
        ],
      ),
      'received_request': FieldValue.arrayRemove(
        [
          opid,
        ],
      ),
    });
    CoreHelper().showDefaultActionDialog(context, 'Friend request accepted');
  }

  @override
  void initState() {
    super.initState();
    _collectionReference = FirebaseFirestore.instance.collection('users');
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text('Friend Request'),
        actions: [
          IconButton(
            icon: Icon(Icons.person_add_alt_1_outlined),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => FindNewFriends(),
              ),
            ),
          ),
        ],
        bottom: TabBar(
          tabs: [
            Tab(
              text: 'Sent',
            ),
            Tab(
              text: 'Received',
            ),
          ],
          controller: _tabController,
        ),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.active) {
            Map<String, dynamic> _userDataMap = snapshot.data.data();
            return TabBarView(
              controller: _tabController,
              children: [
                Container(
                  child: _userDataMap.containsKey('sent_request') &&
                          snapshot.data.get('sent_request') != null &&
                          _userDataMap['sent_request'].isNotEmpty
                      ? ListView.builder(
                          itemBuilder: (_, index) {
                            List<dynamic> data =
                                snapshot.data.get('sent_request');
                            //_collectionReference.doc(data[index]).get();
                            return StreamBuilder<DocumentSnapshot>(
                              builder: (_, snap) {
                                if (snap.connectionState ==
                                    ConnectionState.active) {
                                  return ListTile(
                                    leading: ClipOval(
                                      child: snap.data.get('dp_url') != null &&
                                              snap.data.get('dp_url') != '' &&
                                              !snap.data.get('hidden_search_dp')
                                          ? CachedNetworkImage(
                                              imageUrl: snap.data.get('dp_url'),
                                              height: 40.0,
                                              width: 40.0,
                                              fit: BoxFit.cover,
                                            )
                                          : Container(
                                              color: Colors.grey.shade800,
                                              height: 40.0,
                                              width: 40.0,
                                              child: Center(
                                                child: Icon(
                                                  Icons.person_outline,
                                                ),
                                              ),
                                            ),
                                    ),
                                    title: Text(
                                      snap.data.get('name'),
                                    ),
                                    subtitle: Text(
                                      snap.data.get('hidden_search_email')
                                          ? CoreHelper().getHiddenEmail(
                                              snap.data.get('email'),
                                            )
                                          : snap.data.get('email'),
                                    ),
                                    trailing: IconButton(
                                      icon: Icon(Icons.delete_outline),
                                      tooltip: 'Delete request',
                                      onPressed: () =>
                                          _deleteRequest(data[index]),
                                    ),
                                  );
                                } else {
                                  return Container();
                                }
                              },
                              stream: _collectionReference
                                  .doc(data[index])
                                  .snapshots(),
                            );
                          },
                          itemCount: (snapshot.data.get('sent_request')
                                  as List<dynamic>)
                              .length,
                        )
                      : Container(
                          child: Center(
                            child: Text('No sent request',
                                style: Theme.of(context).textTheme.subtitle2),
                          ),
                        ),
                ),
                Container(
                  child: _userDataMap.containsKey('received_request') &&
                          snapshot.data.get('received_request') != null &&
                          _userDataMap['received_request'].isNotEmpty
                      ? ListView.builder(
                          itemBuilder: (_, index) {
                            List<dynamic> data =
                                snapshot.data.get('received_request');
                            return StreamBuilder<DocumentSnapshot>(
                              builder: (_, snap) {
                                if (snap.connectionState ==
                                    ConnectionState.active) {
                                  return ListTile(
                                    leading: ClipOval(
                                      child: snap.data.get('dp_url') != null &&
                                              snap.data.get('dp_url') != '' &&
                                              !snap.data.get('hidden_search_dp')
                                          ? CachedNetworkImage(
                                              imageUrl: snap.data.get('dp_url'),
                                              height: 40.0,
                                              width: 40.0,
                                              fit: BoxFit.cover,
                                            )
                                          : Container(
                                              height: 40.0,
                                              width: 40.0,
                                              color: Colors.grey.shade800,
                                              child: Center(
                                                child: Icon(
                                                  Icons.person_outline,
                                                ),
                                              ),
                                            ),
                                    ),
                                    title: Text(
                                      snap.data.get('name'),
                                    ),
                                    subtitle: Text(
                                      snap.data.get('hidden_search_email')
                                          ? CoreHelper().getHiddenEmail(
                                              snap.data.get('email'),
                                            )
                                          : snap.data.get('email'),
                                    ),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: Icon(FlutterIcons.done_mdi),
                                          tooltip: 'Accept request',
                                          onPressed: () =>
                                              _acceptRequest(data[index]),
                                        ),
                                        SizedBox(
                                          width: 5.0,
                                        ),
                                        IconButton(
                                          icon: Icon(FlutterIcons.cancel_mdi),
                                          tooltip: 'Reject request',
                                          onPressed: () => _deleteRequest(
                                            data[index],
                                            oposite: true,
                                          ),
                                        )
                                      ],
                                    ),
                                  );
                                } else {
                                  return Container();
                                }
                              },
                              stream: _collectionReference
                                  .doc(data[index])
                                  .snapshots(),
                            );
                          },
                          itemCount: (snapshot.data.get('received_request')
                                  as List<dynamic>)
                              .length,
                        )
                      : Container(
                          child: Center(
                            child: Text('No received request',
                                style: Theme.of(context).textTheme.subtitle2),
                          ),
                        ),
                ),
              ],
            );
          } else {
            return Center(
              child: CoreHelper().getCircleProgressIndicator(),
            );
          }
        },
        stream: _collectionReference
            .doc(FirebaseAuth.instance.currentUser.uid)
            .snapshots(),
      ),
    );
  }
}
