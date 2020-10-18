import 'package:DChat/constants/const.dart';
import 'package:DChat/helpers/corehelper.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:string_similarity/string_similarity.dart';

class FindNewFriends extends StatefulWidget {
  @override
  _FindNewFriendsState createState() => _FindNewFriendsState();
}

class _FindNewFriendsState extends State<FindNewFriends> {
  String searchTerm = '';
  TextEditingController _searchController = TextEditingController();
  CollectionReference _collectionReference;
  Map<String, dynamic> _currentUserData;
  List<QueryDocumentSnapshot> _foundFilteredDoc = [];
  bool _isSearching = false;
  FocusNode _searchFocusNode = FocusNode();

  /* _sendDM(int index) async {
    if (!await CoreHelper().isConnectedToInternet()) {
      CoreHelper().showDefaultActionDialog(
        context,
        NO_INTERNET_STRING,
        title: 'Error',
      );
      return;
    }
    try {
      CollectionReference dmCollection =
          FirebaseFirestore.instance.collection('chats');
      var snap =
          (await _collectionReference.doc(_foundFilteredDoc[index].id).get())
              .data();
      if (snap['connections'] != null &&
          (snap['connections'] as List<dynamic>).contains(_currentUserData)) {
        CoreHelper().showDefaultActionDialog(
          context,
          'Looks like ${_foundFilteredDoc[index].get("name")} is already in a conversation with you so you can not send him/her a new friend request.',
          title: 'Error',
        );
      } else {
        await _collectionReference.doc(_foundFilteredDoc[index].id).update(
          {
            'connections': [_currentUserData['id']],
          },
        );
        await _collectionReference.doc(_currentUserData['id']).update(
          {
            'connections': [_foundFilteredDoc[index].get('id')],
          },
        );
        var nDocRef = await dmCollection.add({
          'created_at': Timestamp.now(),
          'type': 'single',
          'members': [
            _currentUserData['id'],
            _foundFilteredDoc[index].get('id')
          ],
          'requested_members': [
            _currentUserData['id'],
          ],
          'blocked_members': []
        });
        if (nDocRef != null) {
          var ndRef = await nDocRef.collection('chats').add({
            'type': 'request',
            'message':
                '${_currentUserData["name"]} want to start a conversation with you. Press the accept button to accept this conversation request.',
            'read_by': [],
            'accepted': false,
            'rejected': false,
            'sender': _currentUserData['id'],
            'time': Timestamp.now(),
          });
          if (ndRef != null) {
            _foundFilteredDoc.removeAt(index);
            if (mounted) {
              setState(() {});
            }
          } else {
            await nDocRef.delete();
            CoreHelper().showDefaultActionDialog(
              context,
              SOMETHING_WENT_WRONG,
              title: 'Error',
            );
          }
        } else {
          CoreHelper().showDefaultActionDialog(
            context,
            SOMETHING_WENT_WRONG,
            title: 'Error',
          );
        }
      }
    } catch (e) {
      CoreHelper().showDefaultActionDialog(
        context,
        SOMETHING_WENT_WRONG,
        title: 'Error',
      );
      print(e.toString());
    }
  } */

  _sendFriendRequest(int index) async {
    if (!await CoreHelper().isConnectedToInternet()) {
      CoreHelper().showDefaultActionDialog(
        context,
        NO_INTERNET_STRING,
        title: 'Error',
      );
      return;
    }
    await _collectionReference.doc(_currentUserData['id']).update(
      {
        'sent_request': FieldValue.arrayUnion(
          [_foundFilteredDoc[index].get('id')],
        ),
      },
    );
    await _collectionReference.doc(_foundFilteredDoc[index].get('id')).update(
      {
        'received_request': FieldValue.arrayUnion(
          [_currentUserData['id']],
        ),
      },
    );
    CoreHelper().showDefaultActionDialog(context,
        'Friend request sent to ${_foundFilteredDoc[index].get("name")}');
    _foundFilteredDoc.removeAt(index);
    if (mounted) {
      setState(() {});
    }
  }

  _searchUser() async {
    if (searchTerm == _searchController.text.trim()) {
      return;
    }
    searchTerm = _searchController.text.trim();
    if (searchTerm.isNotEmpty) {
      if (!await CoreHelper().isConnectedToInternet()) {
        CoreHelper().showDefaultActionDialog(
          context,
          NO_INTERNET_STRING,
          title: 'Error',
        );
        return;
      }
      _isSearching = true;
      setState(() {});
      if (_currentUserData == null) {
        _currentUserData = (await FirebaseFirestore.instance
                .collection('users')
                .doc(FirebaseAuth.instance.currentUser.uid)
                .get())
            .data();
      }
      List<dynamic> _userConnections = [];
      if (_currentUserData['connections'] != null &&
          (_currentUserData['connections'] as List<dynamic>).isNotEmpty) {
        _userConnections = _currentUserData['connections'];
      }

      List<dynamic> _receivedRequest = [];
      if (_currentUserData.containsKey('received_request') &&
          _currentUserData['received_request'] != null) {
        _receivedRequest = _currentUserData['received_request'];
      }

      List<dynamic> _sentRequest = [];
      if (_currentUserData.containsKey('sent_request') &&
          _currentUserData['sent_request'] != null) {
        _sentRequest = _currentUserData['sent_request'];
      }

      //print(_userConnections.toString());

      var snapshot = await _collectionReference.get();
      _foundFilteredDoc = snapshot.docs
          .where(
            (element) =>
                (StringSimilarity.compareTwoStrings(searchTerm.toLowerCase(),
                            element.get('name').toLowerCase()) >
                        0.4 ||
                    (element.get('name') as String).toLowerCase().contains(
                          searchTerm.toLowerCase(),
                        )) &&
                element.get('id') != _currentUserData['id'] &&
                !_userConnections.contains(
                  element.get('id'),
                ) &&
                !_receivedRequest.contains(element.get('id')) &&
                !_sentRequest.contains(
                  element.get('id'),
                ),
          )
          .toList();
      _isSearching = false;
      if (mounted) {
        setState(() {});
      }
      if (_foundFilteredDoc.isEmpty) {
        CoreHelper().showDefaultActionDialog(
          context,
          'Nothing found matching your search term.',
          title: 'Info',
        );
        _searchFocusNode.requestFocus();
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _collectionReference = FirebaseFirestore.instance.collection('users');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        //automaticallyImplyLeading: false,
        title: ClipRRect(
          borderRadius: BorderRadius.circular(5.0),
          child: TextField(
            controller: _searchController,
            autocorrect: true,
            autofocus: true,
            onSubmitted: (_) => _searchUser(),
            focusNode: _searchFocusNode,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              isDense: true,
              hintText: 'Search a friend...',
              fillColor: Colors.grey.shade800,
              filled: true,
              border: InputBorder.none,
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.search),
            onPressed: _isSearching ? null : _searchUser,
          ),
        ],
      ),
      body: Container(
        child: _isSearching
            ? Center(
                child: CoreHelper().getCircleProgressIndicator(),
              )
            : _foundFilteredDoc.isNotEmpty
                ? ListView.builder(
                    padding: const EdgeInsets.only(
                      left: 10.0,
                      right: 10.0,
                      top: 10.0,
                      bottom: 20.0,
                    ),
                    itemBuilder: (_, index) {
                      Map<String, dynamic> data =
                          _foundFilteredDoc[index].data();
                      return ListTile(
                        leading: ClipOval(
                          child: (data['hidden_search_dp'] as bool) &&
                                  data.containsKey('dp_url') &&
                                  data['dp_url'] != null &&
                                  (data['dp_url'] as String).isNotEmpty
                              ? CachedNetworkImage(
                                  height: 50.0,
                                  width: 50.0,
                                  fit: BoxFit.cover,
                                  imageUrl: data['dp_url'],
                                )
                              : Container(
                                  height: 50.0,
                                  width: 50.0,
                                  color: Colors.grey.shade800,
                                  child: Icon(Icons.person_outline),
                                ),
                        ),
                        title: Text(
                          data['name'],
                        ),
                        subtitle: Text(
                          data['hidden_search_email']
                              ? CoreHelper().getHiddenEmail(data['email'])
                              : data['email'],
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: IconButton(
                          color: Theme.of(context).primaryColor,
                          icon: Icon(Icons.person_add_alt_1),
                          onPressed: () => _sendFriendRequest(index),
                        ),
                      );
                    },
                    itemCount: _foundFilteredDoc.length,
                  )
                : Container(),
      ),
    );
  }
}
