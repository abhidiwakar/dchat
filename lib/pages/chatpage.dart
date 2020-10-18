import 'dart:async';

import 'package:DChat/constants/const.dart';
import 'package:DChat/helpers/corehelper.dart';
import 'package:DChat/widgets/chatbox.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:calendar_time/calendar_time.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:grouped_list/grouped_list.dart';

class ChatPage extends StatefulWidget {
  final String opUserId;
  final String currentUserId;
  final String docId;
  final String initialName;
  final String initialDpUrl;

  const ChatPage(
    this.opUserId,
    this.currentUserId,
    this.docId, {
    Key key,
    @required this.initialName,
    @required this.initialDpUrl,
  }) : super(key: key);
  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  TextEditingController _messageController = TextEditingController();
  ScrollController _scrollController = ScrollController(keepScrollOffset: true);
  FirebaseFirestore _firestore = FirebaseFirestore.instance;
  StreamController<QuerySnapshot> _stream = StreamController();
  FocusNode _messageFocusNode = FocusNode();
  FToast _fToast;
  bool _isSending = false;
  bool _isFirstScroll = true;
  int _newMessageCounter = 0;

  _showMenuDialog() {
    //showCupertinoDialog(context: context, builder: CupertinoPopup())
    showCupertinoModalPopup(
      context: context,
      builder: (_) => CupertinoActionSheet(
        title: Text('Choose Action'),
        actions: [
          CupertinoButton(
            child: Text('Information'),
            onPressed: () {},
          ),
          CupertinoButton(
            child: Text('Copy'),
            onPressed: () {},
          ),
          CupertinoButton(
            child: Text('Forward'),
            onPressed: () {},
          ),
          CupertinoButton(
            child: Text(
              'Delete Message',
              style: TextStyle(color: Colors.red),
            ),
            onPressed: () {},
          ),
        ],
        cancelButton: CupertinoButton(
          color: Colors.red,
          child: Text('Cancel'),
          onPressed: () {},
        ),
      ),
    );
  }

  _longPressHandler() async {
    _showMenuDialog();
  }

  _sendMessage() async {
    String message = _messageController.text.trim();
    if (message.isNotEmpty) {
      _isSending = true;
      setState(() {});
      if (!await CoreHelper().isConnectedToInternet()) {
        _isSending = false;
        if (mounted) {
          setState(() {});
        }
        CoreHelper().showToast(
          context,
          _fToast,
          NO_INTERNET_STRING,
          titleForIOS: 'Error',
        );
        return;
      }
      Map<String, dynamic> _dataMap = Map<String, dynamic>();
      _dataMap['attachedUrl'] = '';
      _dataMap['message'] = message;
      _dataMap['read_by'] = [];
      _dataMap['sender'] = widget.currentUserId;
      _dataMap['time'] = Timestamp.now();
      _dataMap['type'] = 'message';
      _dataMap['is_deleted'] = <String>[];
      try {
        await _firestore
            .collection('chats')
            .doc(widget.docId)
            .collection('chats')
            .add(_dataMap);
        _messageController.text = '';
        _isSending = false;
        if (mounted) {
          setState(() {});
        }
        _scrollToMax(smoothScroll: true, duration: 0);
      } catch (e) {
        _isSending = false;
        if (mounted) {
          setState(() {});
        }
        CoreHelper().showToast(
          context,
          _fToast,
          SOMETHING_WENT_WRONG,
          titleForIOS: 'Error',
        );
        print(e.toString());
      }
    }
  }

  _scrollToMax({int duration = 300, bool smoothScroll = false}) {
    Future.delayed(Duration(milliseconds: duration), () {
      if (_scrollController != null && _scrollController.hasClients) {
        if (smoothScroll) {
          print('Scrolling...');
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: Duration(milliseconds: 400),
            curve: Curves.ease,
          );
        } else {
          print('Scrolling directly...');
          _scrollController.jumpTo(
            _scrollController.position.maxScrollExtent,
          );
        }
      } else {
        print('Scrolling failed...');
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _fToast = FToast();
    _fToast.init(context);
    _stream.addStream(
      _firestore
          .collection('chats')
          .doc(widget.docId)
          .collection('chats')
          .orderBy('time')
          .snapshots(),
    );
    _scrollToMax();
    _isFirstScroll = false;
  }

  _acceptRequest(DocumentReference documentReference) async {
    await documentReference.update({'accepted': true});
  }

  _rejectRequest(DocumentReference documentReference) async {
    //await documentReference.update({'rejected': true});
    FirebaseFirestore.instance.collection('users').doc(widget.opUserId).update({
      'connections': FieldValue.arrayRemove([widget.currentUserId])
    });
    FirebaseFirestore.instance
        .collection('users')
        .doc(widget.currentUserId)
        .update({
      'connections': FieldValue.arrayRemove([widget.opUserId])
    });
    print(widget.docId);
    Navigator.pop(context);

    await documentReference.delete();
    await FirebaseFirestore.instance
        .collection('chats')
        .doc(widget.docId)
        .delete();
  }

  @override
  void dispose() {
    _stream.close().then((_) => print('Chats stream closed'));
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipOval(
                child: widget.initialDpUrl != null && widget.initialDpUrl != ''
                    ? CachedNetworkImage(
                        imageUrl: widget.initialDpUrl,
                        height: 30.0,
                        width: 30.0,
                        fit: BoxFit.cover,
                      )
                    : Container(
                        height: 30.0,
                        width: 30.0,
                        color: Colors.grey.shade800,
                        child: Center(
                          child: Icon(
                            Icons.person_outline,
                          ),
                        ),
                      ),
              ),
              SizedBox(
                width: 10.0,
              ),
              Text(widget.initialName),
            ],
          ),
        ),
        body: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 10.0,
          ),
          child: StreamBuilder<QuerySnapshot>(
            builder: (_, snap) {
              if (snap.connectionState == ConnectionState.active) {
                var dataDocs = snap.data.docs;
                if (_scrollController != null &&
                    _scrollController.hasClients &&
                    _scrollController.offset != null &&
                    _scrollController.position != null &&
                    _scrollController.position.maxScrollExtent != null &&
                    _scrollController.offset !=
                        _scrollController.position.maxScrollExtent) {
                  print('Can handle scroll');
                  print('Current Offset: ${_scrollController.offset}');
                  print(
                      'Max Offset: ${_scrollController.position.maxScrollExtent}');
                  print(
                      'Scroll Probability: ${100 - ((_scrollController.offset * 100) / _scrollController.position.maxScrollExtent)}');
                  if (dataDocs[dataDocs.length - 1].get('sender') !=
                      widget.currentUserId) {
                    if ((100 -
                            ((_scrollController.offset * 100) /
                                    _scrollController.position.maxScrollExtent)
                                .floor()) >
                        1.5) {
                      _newMessageCounter++;
                      print('New message arrived');
                      Fluttertoast.showToast(
                        msg: _newMessageCounter > 1
                            ? 'New message arrived ($_newMessageCounter)'
                            : 'New message arrived',
                        backgroundColor: Theme.of(context).primaryColor,
                        gravity: ToastGravity.TOP,
                        textColor: Colors.white,
                        toastLength: Toast.LENGTH_LONG,
                      );
                    }
                  }
                } else {
                  _scrollToMax(smoothScroll: true);
                }
                return Column(
                  children: [
                    Expanded(
                      child: GroupedListView<dynamic, String>(
                        controller: _scrollController,
                        padding: const EdgeInsets.only(bottom: 20.0),
                        elements: dataDocs,
                        groupBy: (element) => element['time']
                            .toDate()
                            .toLocal()
                            .toString()
                            .substring(0, 10),
                        sort: false,
                        groupSeparatorBuilder: (String groupByValue) =>
                            Container(
                          margin: const EdgeInsets.only(
                            top: 5.0,
                            bottom: 10.0,
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 10.0),
                          width: double.infinity,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 5.0,
                                  horizontal: 10.0,
                                ),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(
                                    50.0,
                                  ),
                                  color: Colors.grey.shade900,
                                ),
                                child: Text(
                                  CalendarTime(
                                    DateTime.parse(
                                      groupByValue.trim() + ' 01:00:04Z',
                                    ),
                                  ).isToday
                                      ? 'Today'
                                      : CalendarTime(
                                          DateTime.parse(
                                            groupByValue + ' 01:00:04Z',
                                          ),
                                        ).isYesterday
                                          ? 'Yesterday'
                                          : groupByValue,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        itemBuilder: (context, dynamic element) {
                          Map<String, dynamic> dmpa =
                              (element as DocumentSnapshot).data();
                          if (dmpa['is_deleted'] != null &&
                              (dmpa['is_deleted'] as List<dynamic>)
                                  .contains(widget.currentUserId)) {
                            return Container();
                          } else {
                            int currentDocIndex = dataDocs
                                .indexWhere((el) => element.id == el.id);
                            int lastIndex = -1;
                            int nextIndex = -1;
                            if (currentDocIndex > 0) {
                              lastIndex = currentDocIndex - 1;
                            }
                            if (currentDocIndex < dataDocs.length) {
                              nextIndex = currentDocIndex + 1;
                            }
                            return ChatBox(
                              dataDocs: element,
                              previousSender:
                                  dataDocs.asMap().containsKey(lastIndex)
                                      ? dataDocs[lastIndex].get('sender')
                                      : '',
                              nextSender:
                                  dataDocs.asMap().containsKey(nextIndex)
                                      ? dataDocs[nextIndex].get('sender')
                                      : '',
                              currentUserId: widget.currentUserId,
                              longPressHandler: _longPressHandler,
                            );
                          }
                        },
                        useStickyGroupSeparators: false,
                        stickyHeaderBackgroundColor: Colors.transparent,
                        floatingHeader: false,
                        //order: GroupedListOrder.DESC,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(
                        bottom: 8.0,
                        top: 5.0,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.grey.shade900,
                                borderRadius: BorderRadius.circular(
                                  5.0,
                                ),
                              ),
                              child: TextField(
                                focusNode: _messageFocusNode,
                                controller: _messageController,
                                keyboardType: TextInputType.multiline,
                                maxLines: 3,
                                minLines: 1,
                                onTap: () => _scrollToMax(
                                    duration: 300, smoothScroll: true),
                                //enabled: !_isSending,
                                decoration: InputDecoration(
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 10.0,
                                    vertical: 4.0,
                                  ),
                                  border: InputBorder.none,
                                  hintText: 'Type a message to send...',
                                ),
                              ),
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.send,
                              color: Theme.of(context).primaryColor,
                            ),
                            onPressed: _isSending ? null : _sendMessage,
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              } else if (snap.connectionState == ConnectionState.waiting) {
                return Center(
                  child: CoreHelper().getCircleProgressIndicator(),
                );
              } else {
                CoreHelper().showDefaultActionDialog(
                  context,
                  'Something went wrong.',
                  title: 'Error',
                );
                return Container();
              }
            },
            stream: _stream.stream,
          ),
        ),
      ),
    );
  }
}
