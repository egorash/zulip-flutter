import 'package:flutter/material.dart';

import '../../../api/model/model.dart';
import '../../../model/content.dart';
import '../../themes/content_theme.dart';
import '../../values/theme.dart';
import '../../widgets/poll.dart';
import 'widgets/block_content_list.dart';

/// The entire content of a message, aka its body.
///
/// This does not include metadata like the sender's name and avatar, the time,
/// or the message's status as starred or edited.
class MessageContent extends StatelessWidget {
  const MessageContent({
    super.key,
    required this.isMe,
    required this.message,
    required this.content,
    required this.isEdited,
  });

  final bool isMe;
  final Message message;
  final ZulipMessageContent content;
  final bool isEdited;

  @override
  Widget build(BuildContext context) {
    final content = this.content;
    final designVariables = DesignVariables.of(context);

    return Container(
      margin: EdgeInsets.only(
        top: 4,
        right: isMe ? 0 : 40,
        left: isMe ? 40 : 0,
      ),
      constraints: isEdited ? BoxConstraints(minWidth: 50) : null,
      padding: EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: isMe
            ? designVariables.myMessageBackground
            : designVariables.otherMessageBackground,
        borderRadius: BorderRadius.circular(12).copyWith(
          topLeft: isMe ? null : Radius.circular(0),
          topRight: !isMe ? null : Radius.circular(0),
        ),
      ),
      child: Stack(
        children: [
          Align(
            alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
            child: Padding(
              padding: EdgeInsets.only(bottom: isEdited ? 12 : 0),
              child: InheritedMessage(
                message: message,
                child: DefaultTextStyle(
                  style: ContentTheme.of(context).textStylePlainParagraph,
                  child: switch (content) {
                    ZulipContent() => BlockContentList(
                      nodes: content.nodes,
                      isMe: isMe,
                    ),
                    PollContent() => PollWidget(
                      messageId: message.id,
                      poll: content.poll,
                    ),
                  },
                ),
              ),
            ),
          ),
          if (isEdited)
            Positioned(
              right: 0,
              bottom: 2,
              child: Text(
                'изм.',
                style: TextStyle(
                  fontSize: 12,
                  color: designVariables.labelEdited,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class InheritedMessage extends InheritedWidget {
  const InheritedMessage({
    super.key,
    required this.message,
    required super.child,
  });

  final Message message;

  @override
  bool updateShouldNotify(covariant InheritedMessage oldWidget) =>
      !identical(oldWidget.message, message);

  static Message of(BuildContext context) {
    final widget = context
        .dependOnInheritedWidgetOfExactType<InheritedMessage>();
    assert(widget != null, 'No InheritedMessage ancestor');
    return widget!.message;
  }
}
