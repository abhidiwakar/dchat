import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ChatBox extends StatelessWidget {
  const ChatBox({
    Key key,
    @required this.dataDocs,
    @required this.currentUserId,
    @required this.longPressHandler,
    this.previousSender,
    this.nextSender,
  }) : super(key: key);

  final DocumentSnapshot dataDocs;
  final String currentUserId;
  final String previousSender;
  final String nextSender;
  final Function longPressHandler;

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width * 70 / 100;
    Timestamp timestamp = dataDocs.get('time');
    return GestureDetector(
      onLongPress: this.longPressHandler,
      child: Wrap(
        children: [
          Align(
            alignment: dataDocs.get('sender') != currentUserId
                ? Alignment.topLeft
                : Alignment.topRight,
            child: Container(
              constraints: BoxConstraints(
                maxWidth: width,
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 10.0,
                vertical: 10.0,
              ),
              margin: const EdgeInsets.only(
                top: 5.0,
              ),
              decoration: dataDocs.get('sender') != currentUserId
                  ? BoxDecoration(
                      color: dataDocs.get('sender') != currentUserId
                          ? Theme.of(context).primaryColor
                          : Colors.grey.shade700,
                      borderRadius: BorderRadius.only(
                        topRight: Radius.circular(10.0),
                        bottomRight: Radius.circular(10.0),
                        topLeft:
                            previousSender != null && previousSender.isNotEmpty
                                ? previousSender != currentUserId
                                    ? Radius.circular(0.0)
                                    : Radius.circular(10.0)
                                : Radius.circular(10.0),
                        bottomLeft: nextSender != null && nextSender.isNotEmpty
                            ? nextSender != currentUserId
                                ? Radius.circular(0.0)
                                : Radius.circular(10.0)
                            : Radius.circular(10.0),
                      ),
                    )
                  : BoxDecoration(
                      color: dataDocs.get('sender') != currentUserId
                          ? Theme.of(context).primaryColor
                          : Colors.grey.shade700,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(10.0),
                        bottomLeft: Radius.circular(10.0),
                        topRight:
                            previousSender != null && previousSender.isNotEmpty
                                ? previousSender != currentUserId
                                    ? Radius.circular(10.0)
                                    : Radius.circular(0.0)
                                : Radius.circular(10.0),
                        bottomRight: nextSender != null && nextSender.isNotEmpty
                            ? nextSender != currentUserId
                                ? Radius.circular(10.0)
                                : Radius.circular(0.0)
                            : Radius.circular(10.0),
                      ),
                    ),
              child: Column(
                crossAxisAlignment: dataDocs.get('sender') != currentUserId
                    ? CrossAxisAlignment.start
                    : CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    dataDocs.get('message'),
                    style: Theme.of(context)
                        .textTheme
                        .bodyText1
                        .copyWith(fontSize: 16.0),
                  ),
                  Text(
                    DateFormat('hh:mm a').format(timestamp.toDate().toLocal()),
                    style: Theme.of(context).textTheme.caption,
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
