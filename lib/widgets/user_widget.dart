import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

class UserMessageWidget extends StatelessWidget {
  const UserMessageWidget({
    super.key,
    required this.message,
  });

  final String message;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.9,
          ),
          decoration: BoxDecoration(
            color: Color(0xFFD6AF38),
            borderRadius: BorderRadius.circular(18),
          ),
          padding: const EdgeInsets.all(15),
          margin: const EdgeInsets.only(bottom: 8),
          child: MarkdownBody(
                  selectable: true,
                  data: message,
                )),
    );
  }
}