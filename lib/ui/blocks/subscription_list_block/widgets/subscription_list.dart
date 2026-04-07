import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../api/model/model.dart';
import '../../../../get/services/domains/unreads/unreads_service.dart';
import '../subscription_list_block.dart';
import 'subscription_item.dart';

class SubscriptionList extends StatelessWidget {
  const SubscriptionList({
    super.key,
    required this.subscriptions,
    required this.showTopicListButtonInActionSheet,
    required this.onChannelSelect,
  });

  final List<Subscription> subscriptions;
  final bool showTopicListButtonInActionSheet;
  final OnChannelSelectCallback onChannelSelect;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final unreadsModel = UnreadsService.to.unreads;
      return SliverList.builder(
        itemCount: subscriptions.length,
        itemBuilder: (BuildContext context, int index) {
          final subscription = subscriptions[index];
          final unreadCount =
              unreadsModel?.countInChannel(subscription.streamId) ?? 0;
          final showMutedUnreadBadge =
              unreadCount == 0 &&
              (unreadsModel?.countInChannelNarrow(subscription.streamId) ?? 0) >
                  0;
          return SubscriptionItem(
            subscription: subscription,
            unreadCount: unreadCount,
            showMutedUnreadBadge: showMutedUnreadBadge,
            showTopicListButtonInActionSheet: showTopicListButtonInActionSheet,
            onChannelSelect: onChannelSelect,
          );
        },
      );
    });
  }
}
