import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../get/app_pages.dart';
import '../../../get/services/domains/unreads/unreads_service.dart';
import '../../../generated/l10n/zulip_localizations.dart';
import '../../../get/services/store_service.dart';
import '../../../model/narrow.dart';
import '../../utils/page.dart';
import 'widgets/recent_dm_conversations_item.dart';

typedef OnDmSelectCallback = void Function(DmNarrow narrow);

class RecentDmConversationsPageBody extends StatelessWidget {
  const RecentDmConversationsPageBody({
    super.key,
    this.hideDmsIfUserCantPost = false,
    this.onDmSelect,
  });

  final bool hideDmsIfUserCantPost;
  final OnDmSelectCallback? onDmSelect;

  @override
  Widget build(BuildContext context) {
    final zulipLocalizations = ZulipLocalizations.of(context);
    final store = requirePerAccountStore();
    final recentDmView = store.recentDmConversationsView;

    return Obx(() {
      final sorted = recentDmView.sorted.toList();

      if (sorted.isEmpty) {
        return PageBodyEmptyContentPlaceholder(
          header:
              zulipLocalizations.recentDmConversationsEmptyPlaceholderHeader,
          message:
              zulipLocalizations.recentDmConversationsEmptyPlaceholderMessage,
        );
      }

      return _DmConversationList(
        hideDmsIfUserCantPost: hideDmsIfUserCantPost,
        onDmSelect: onDmSelect,
      );
    });
  }
}

class _DmConversationList extends StatelessWidget {
  const _DmConversationList({
    required this.hideDmsIfUserCantPost,
    required this.onDmSelect,
  });

  final bool hideDmsIfUserCantPost;
  final OnDmSelectCallback? onDmSelect;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final store = requirePerAccountStore();
      final recentDmView = store.recentDmConversationsView;
      final bottomInsets = MediaQuery.paddingOf(context).bottom;
      recentDmView.map; // depend on map changes
      recentDmView.latestMessages; // depend on latestMessages changes
      final sorted = recentDmView.sorted.toList();

      return SafeArea(
        bottom: false,
        child: ListView.builder(
          padding: EdgeInsets.only(bottom: bottomInsets + 90),
          itemCount: sorted.length,
          itemBuilder: (context, index) {
            final narrow = sorted[index];
            if (store.shouldMuteDmConversation(narrow)) {
              return const SizedBox.shrink();
            }
            if (hideDmsIfUserCantPost) {
              final hasDeactivatedUser = narrow.otherRecipientIds.any(
                (id) => !(store.getUser(id)?.isActive ?? true),
              );
              if (hasDeactivatedUser) {
                return const SizedBox.shrink();
              }
            }
            final lastMessage = recentDmView.latestMessages[narrow];
            return RecentDmConversationsItem(
              narrow: narrow,
              unreadCount:
                  UnreadsService.to.unreads?.countInDmNarrow(narrow) ?? 0,
              lastMessage: lastMessage.obs,
              onDmSelect:
                  onDmSelect ??
                  (narrow) {
                    Get.toNamed<dynamic>(
                      AppRoutes.messageList,
                      arguments: {'narrow': narrow},
                    );
                  },
            );
          },
        ),
      );
    });
  }
}
