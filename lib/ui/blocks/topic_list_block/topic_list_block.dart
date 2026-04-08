import 'package:flutter/material.dart';

import '../../../api/model/model.dart';
import '../../../get/services/store_service.dart';
import '../../widgets/app_bar.dart';
import '../../utils/page.dart';
import '../../values/theme.dart';
import 'widgets/topic_list.dart';
import 'widgets/topic_list_app_bar_title.dart';

// А это у нас блок списка тем
class TopicItemData {
  final TopicName topic;
  final int unreadCount;
  final bool hasMention;
  final int maxId;

  const TopicItemData({
    required this.topic,
    required this.unreadCount,
    required this.hasMention,
    required this.maxId,
  });
}

class TopicListPage extends StatelessWidget {
  const TopicListPage({super.key, required this.streamId});

  final int streamId;

  static AccountRoute<void> buildRoute({
    required BuildContext context,
    required int streamId,
  }) {
    return MaterialAccountWidgetRoute(
      context: context,
      page: TopicListPage(streamId: streamId),
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = requirePerAccountStore();
    final appBarBackgroundColor = colorSwatchFor(
      context,
      store.subscriptions[streamId],
    ).barBackground;

    return PageRoot(
      child: Scaffold(
        appBar: ZulipAppBar(
          backgroundColor: appBarBackgroundColor,
          buildTitle: (willCenterTitle) => TopicListAppBarTitle(
            streamId: streamId,
            willCenterTitle: willCenterTitle,
          ),
        ),
        body: TopicList(streamId: streamId),
      ),
    );
  }
}
