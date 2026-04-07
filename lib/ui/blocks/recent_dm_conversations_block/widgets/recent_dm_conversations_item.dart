import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:html/parser.dart';

import '../../../../api/model/model.dart';
import '../../../../get/services/domains/users/users_service.dart';
import '../../../../get/services/store_service.dart';
import '../../../../model/narrow.dart';
import '../../../animations.dart';
import '../../../values/icons.dart';
import '../../../values/theme.dart';
import '../../../widgets/counter_badge.dart';
import '../../../widgets/user.dart';
import '../recent_dm_conversations.dart';

class RecentDmConversationsItem extends StatelessWidget {
  const RecentDmConversationsItem({
    super.key,
    required this.narrow,
    required this.unreadCount,
    required this.lastMessage,
    required this.onDmSelect,
  });

  final DmNarrow narrow;
  final int unreadCount;
  final Rx<Message?> lastMessage;
  final OnDmSelectCallback onDmSelect;

  static const double _avatarSize = 48;

  @override
  Widget build(BuildContext context) {
    final designVariables = DesignVariables.of(context);
    final usersService = UsersService.to;

    final InlineSpan title;
    final Widget avatar;
    int? userIdForPresence;
    switch (narrow.otherRecipientIds) {
      // TODO dedupe with DM items in [InboxPage]
      case []:
        final selfUser = usersService.selfUser;
        title = TextSpan(
          text: selfUser?.fullName ?? '',
          children: [
            UserStatusEmoji.asWidgetSpan(
              userId: usersService.selfUserId,
              fontSize: 17,
              textScaler: MediaQuery.textScalerOf(context),
            ),
          ],
        );
        avatar = AvatarImage(
          userId: usersService.selfUserId,
          size: _avatarSize,
        );
      case [var otherUserId]:
        title = TextSpan(
          text: usersService.userDisplayName(otherUserId),
          children: [
            UserStatusEmoji.asWidgetSpan(
              userId: otherUserId,
              fontSize: 17,
              textScaler: MediaQuery.textScalerOf(context),
            ),
          ],
        );
        avatar = AvatarImage(userId: otherUserId, size: _avatarSize);
        userIdForPresence = otherUserId;
      default:
        title = TextSpan(
          // TODO(i18n): List formatting, like you can do in JavaScript:
          //   new Intl.ListFormat('ja').format(['Chris', 'Greg', 'Alya'])
          //   // 'Chris、Greg、Alya'
          text: narrow.otherRecipientIds
              .map(usersService.userDisplayName)
              .join(', '),
        );
        avatar = ColoredBox(
          color: designVariables.avatarPlaceholderBg,
          child: Center(
            child: Icon(
              color: designVariables.avatarPlaceholderIcon,
              ZulipIcons.group_dm,
            ),
          ),
        );
    }

    // TODO(design) check if this is the right variable
    final backgroundColor = designVariables.background;
    return AnimatedPressOpacity(
      opacityEnd: 0.6,
      duration: const Duration(milliseconds: 100),
      child: Material(
        color: backgroundColor,
        child: InkWell(
          onTap: () => onDmSelect(narrow),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(12, 8, 0, 0),
                child: AvatarShape(
                  size: _avatarSize,
                  borderRadius: 99,
                  backgroundColor: userIdForPresence != null
                      ? backgroundColor
                      : null,
                  userIdForPresence: userIdForPresence,
                  child: avatar,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  constraints: const BoxConstraints(minHeight: 48),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: Colors.grey.withValues(alpha: 0.25),
                      ),
                    ),
                  ),
                  padding: const EdgeInsets.only(top: 8, bottom: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text.rich(
                        style: TextStyle(
                          fontSize: 17,
                          height: 1.15,
                          // TODO(design) check if this is the right variable
                          color: designVariables.labelMenuButton,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        title,
                      ),
                      Obx(
                        () => _buildMessagePreview(
                          context,
                          lastMessage.value?.content,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              unreadCount > 0
                  ? Padding(
                      padding: const EdgeInsetsDirectional.only(end: 16),
                      child: CounterBadge(
                        kind: CounterBadgeKind.unread,
                        channelIdForBackground: null,
                        count: unreadCount,
                      ),
                    )
                  : const SizedBox(),
            ],
          ),
        ),
      ),
    );
  }

  String stripHtml(String html) {
    final document = parse(html);
    return document.body?.text.trim() ?? '';
  }

  Widget _buildMessagePreview(BuildContext context, String? preview) {
    final designVariables = DesignVariables.of(context);
    final store = requirePerAccountStore();

    if (preview == null) {
      return Text(
        '',
        style: TextStyle(fontSize: 15, color: Colors.red),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      );
    }

    final isFromMe = lastMessage.value!.senderId == store.selfUserId;
    final prefix = isFromMe ? 'Вы: ' : '';
    final content = stripHtml(preview.replaceAll(RegExp(r'\s+'), ' ').trim());

    return Padding(
      padding: const EdgeInsets.only(top: 4.0),
      child: Text(
        '$prefix$content',
        style: TextStyle(
          fontSize: 13,
          fontFamily: 'Arial',
          fontWeight: FontWeight.w200,
          color: designVariables.labelMenuButton.withValues(alpha: 0.5),
        ),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
