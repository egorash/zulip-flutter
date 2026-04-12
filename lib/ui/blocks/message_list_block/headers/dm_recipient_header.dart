import 'package:flutter/material.dart';

import '../../../../api/model/model.dart';
import '../../../../get/services/domains/users/users_service.dart';
import '../../../../model/narrow.dart';
import '../message_list_block.dart';
import 'recipient_header_date.dart';

class DmRecipientHeader extends StatelessWidget {
  const DmRecipientHeader({
    super.key,
    required this.message,
    required this.narrow,
  });

  final MessageBase<DmConversation> message;
  final Narrow narrow;

  @override
  Widget build(BuildContext context) {
    final usersService = UsersService.to;
    final selfUserId = usersService.selfUserId;

    return GestureDetector(
      onTap: narrow is DmNarrow
          ? null
          : () => Navigator.push(
              context,
              MessageListBlockPage.buildRoute(
                context: context,
                narrow: DmNarrow.ofMessage(message, selfUserId: selfUserId),
              ),
            ),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 11),
        alignment: Alignment.topCenter,
        child: Container(
          padding: EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.black45,
            borderRadius: BorderRadius.circular(12),
          ),
          child: RecipientHeaderDate(message: message),
        ),
      ),
    );
  }
}
