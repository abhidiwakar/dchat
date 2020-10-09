import 'package:flutter/material.dart';

class ToastWidget extends StatelessWidget {
  final String data;
  final Color color;

  const ToastWidget({
    Key key,
    @required this.data,
    this.color = Colors.red,
  }) : assert(data != null);

  @override
  Widget build(BuildContext context) {
    if (data.trim().isNotEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 10.0,
          vertical: 7.0,
        ),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(7.0),
        ),
        child: Text(
          data,
          textAlign: TextAlign.center,
        ),
      );
    } else {
      return Container();
    }
  }
}
