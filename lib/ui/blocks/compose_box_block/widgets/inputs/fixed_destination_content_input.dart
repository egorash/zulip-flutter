import 'package:flutter/material.dart';

import '../../../../../api/route/messages.dart';
import '../../../../../generated/l10n/zulip_localizations.dart';
import '../../../../../get/services/store_service.dart';
import '../../../../../model/narrow.dart';
import '../../compose_box.dart';
import '../typing_notifier.dart';
import 'content_input.dart';

class FixedDestinationContentInput extends StatelessWidget {
  const FixedDestinationContentInput({
    super.key,
    required this.narrow,
    required this.controller,
    required this.getDestination,
    required this.sendButton,
  });

  final SendableNarrow narrow;
  final FixedDestinationComposeBoxController controller;
  final MessageDestination Function() getDestination;
  final Widget sendButton;

  String _hintText(BuildContext context) {
    final zulipLocalizations = ZulipLocalizations.of(context);
    switch (narrow) {
      case TopicNarrow(:final streamId, :final topic):
        final store = requirePerAccountStore();
        final streamName =
            store.streams[streamId]?.name ??
            zulipLocalizations.unknownChannelName;
        return zulipLocalizations.composeBoxChannelContentHint(
          // No i18n of this use of "#" and ">" string; those are part of how
          // Zulip expresses channels and topics, not any normal English punctuation,
          // so don't make sense to translate. See:
          //   https://github.com/zulip/zulip-flutter/pull/1148#discussion_r1941990585
          '#$streamName > ${topic.displayName ?? store.realmEmptyTopicDisplayName}',
        );

      case DmNarrow(otherRecipientIds: []): // The self-1:1 thread.
        return zulipLocalizations.composeBoxSelfDmContentHint;

      case DmNarrow(otherRecipientIds: [final otherUserId]):
        final store = requirePerAccountStore();
        final user = store.getUser(otherUserId);
        if (user == null) {
          return zulipLocalizations.composeBoxGenericContentHint;
        }
        // TODO write a test where the user is muted
        return zulipLocalizations.composeBoxDmContentHint(
          store.userDisplayName(otherUserId, replaceIfMuted: false),
        );

      case DmNarrow(): // A group DM thread.
        return zulipLocalizations.composeBoxGroupDmContentHint;
    }
  }

  @override
  Widget build(BuildContext context) {
    return TypingNotifier(
      destination: narrow,
      controller: controller,
      child: Column(
        children: [
          AnswerMessageBlock(controller: controller),
          ContentInput(
            narrow: narrow,
            showPrefix: true,
            controller: controller,
            hintText: _hintText(context),
            getDestination: getDestination,
            sendButton: sendButton,
          ),
        ],
      ),
    );
  }
}

class AnswerMessageBlock extends StatefulWidget {
  final FixedDestinationComposeBoxController controller;
  const AnswerMessageBlock({super.key, required this.controller});

  @override
  State<AnswerMessageBlock> createState() => _AnswerMessageBlockState();
}

class _AnswerMessageBlockState extends State<AnswerMessageBlock> {
  @override
  void initState() {
    widget.controller.content.addListener(_listenEvent);
    super.initState();
  }

  @override
  void dispose() {
    widget.controller.content.removeListener(_listenEvent);
    super.dispose();
  }

  void _listenEvent() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final answerMessage = widget.controller.content.answerMessage;

    if (answerMessage.isNotEmpty) {
      return Container(
        alignment: Alignment.centerLeft,
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(color: Colors.black),
        child: Row(
          spacing: 8,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(12),
                  bottomLeft: Radius.circular(12),
                ),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 6),
                  decoration: BoxDecoration(
                    //color: Colors.grey.withValues(alpha: 0.2),
                    border: Border(
                      left: BorderSide(width: 5, color: Colors.white),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 0,
                    children: [
                      Text(
                        'В ответ ${answerMessage.name}',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Text(
                        answerMessage.message,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                widget.controller.content.cancelAnswerMessage();
              },
              child: Icon(Icons.close, color: Colors.white),
            ),
          ],
        ),
      );
    } else {
      return SizedBox();
    }
  }
}
