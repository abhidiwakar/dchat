import 'package:DChat/constants/const.dart';
import 'package:DChat/helpers/corehelper.dart';
import 'package:DChat/pages/chatpage.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class NewChatPage extends StatefulWidget {
  @override
  _NewChatPageState createState() => _NewChatPageState();
}

class _NewChatPageState extends State<NewChatPage> {
  _sendMessage(String opuid) async {
    if (!await CoreHelper().isConnectedToInternet()) {
      CoreHelper().showDefaultActionDialog(
        context,
        NO_INTERNET_STRING,
        title: 'Error',
      );
      return;
    }
    String currentUserId = FirebaseAuth.instance.currentUser.uid;
    CollectionReference dmCollection =
        FirebaseFirestore.instance.collection('chats');
    var dref = await dmCollection
        .where('members', arrayContains: [currentUserId, opuid]).get();
    if (dref.docs.length > 0) {
      var vid = dref.docs[0].id;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChatPage(
            opuid,
            currentUserId,
            vid,
            initialName: '',
            initialDpUrl: '',
          ),
        ),
      );
    } else {
      var nDocRef = await dmCollection.add({
        'created_at': Timestamp.now(),
        'type': 'single',
        'members': [
          currentUserId,
          opuid,
        ],
        'blocked_members': []
      });
      if (nDocRef != null) {
        /* await nDocRef.collection('chats').add({
        'type': 'request',
        'message': 'Hey there.',
        'read_by': [],
        'accepted': false,
        'rejected': false,
        'sender': currentUserId,
        'time': Timestamp.now(),
      }); */
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChatPage(
              opuid,
              currentUserId,
              nDocRef.id,
              initialName: '',
              initialDpUrl: '',
            ),
          ),
        );
      } else {
        CoreHelper().showDefaultActionDialog(
          context,
          SOMETHING_WENT_WRONG,
          title: 'Error',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text('New Chat'),
        backgroundColor: Colors.black,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        builder: (_, snap) {
          if (snap.connectionState == ConnectionState.active) {
            Map<String, dynamic> dataMap = snap.data.data();
            if (dataMap.containsKey('connections') &&
                dataMap['connections'].isNotEmpty) {
              return ListView.builder(
                itemBuilder: (_, index) {
                  return StreamBuilder<DocumentSnapshot>(
                    builder: (_, snapshot) {
                      if (snapshot.connectionState == ConnectionState.active) {
                        return ListTile(
                          leading: ClipOval(
                            child: snapshot.data.get('dp_url') != null &&
                                    snapshot.data.get('dp_url') != ''
                                ? CachedNetworkImage(
                                    imageUrl: snapshot.data.get('dp_url'),
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
                            snapshot.data.get('name'),
                          ),
                          subtitle: Text(
                            snapshot.data.get('email'),
                          ),
                          trailing: IconButton(
                            icon: Icon(
                              Icons.send,
                              color: Theme.of(context).primaryColor,
                            ),
                            tooltip: 'Send message',
                            onPressed: () =>
                                _sendMessage(snapshot.data.get('id')),
                          ),
                        );
                      } else {
                        return Container();
                      }
                    },
                    stream: FirebaseFirestore.instance
                        .collection('users')
                        .doc(dataMap['connections'][index])
                        .snapshots(),
                  );
                },
                itemCount: snap.data.get('connections').length,
              );
            } else {
              return Container();
            }
          } else if (snap.connectionState == ConnectionState.waiting) {
            return Center(
              child: CoreHelper().getCircleProgressIndicator(),
            );
          } else {
            return Center(
              child: CoreHelper().getSomethingWrongWidget(),
            );
          }
        },
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(FirebaseAuth.instance.currentUser.uid)
            .snapshots(),
      ),
    );
  }
}
