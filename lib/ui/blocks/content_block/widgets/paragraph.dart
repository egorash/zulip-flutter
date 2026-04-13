import 'package:collection/collection.dart';
import 'package:flutter/material.dart';

import '../../../../model/content.dart';
import 'helpers.dart';

class Paragraph extends StatelessWidget {
  const Paragraph({
    super.key,
    required this.node,
    this.isMe = false,
    this.isAnswer = false,
    this.maxLines,
    this.textOverflow,
  });

  final bool isMe;
  final bool isAnswer;
  final ParagraphNode node;
  final int? maxLines;
  final TextOverflow? textOverflow;

  @override
  Widget build(BuildContext context) {
    // Empty paragraph winds up with zero height.
    // The paragraph has vertical CSS margins, but those have no effect.
    if (node.nodes.isEmpty) return const SizedBox();

    final isAnswerParagraph = isAnswer || ((((node.nodes.firstWhereOrNull((e) => e is LinkNode)) as LinkNode?)
                ?.url
                .contains('narrow')) ??
            false);

    final text = contentBuildBlockInlineContainer(
      node: node,
      style: DefaultTextStyle.of(context).style,
      textAlign: isMe ? TextAlign.start : TextAlign.start,
      maxLines: maxLines,
      textOverflow: textOverflow,
      isAnswer: isAnswerParagraph,
    );

    final needPadding = node.nodes
        .whereType<UserMentionNode>()
        .toList()
        .isEmpty;

    // If the paragraph didn't actually have a `p` element in the HTML,
    // then apply no margins.  (For example, these are seen in list items.)
    if (node.wasImplicit) return text;

    // For a non-empty paragraph, though — and where there was a `p` element
    // for the Zulip CSS to apply to — the margins are real.
    return Padding(
      padding: needPadding
          ? const EdgeInsets.symmetric(vertical: 4)
          : EdgeInsets.only(top: 4),
      child: text,
    );
  }
}
