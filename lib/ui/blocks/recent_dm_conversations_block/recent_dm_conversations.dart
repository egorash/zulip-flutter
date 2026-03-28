import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../get/app_pages.dart';
import '../../../get/services/domains/unreads/unreads_service.dart';
import '../../../generated/l10n/zulip_localizations.dart';
import '../../../get/services/store_service.dart';
import '../../../model/narrow.dart';
import '../../../model/recent_dm_conversations.dart';
import '../../../model/unreads.dart';
import '../../utils/page.dart';
import 'widgets/recent_dm_conversations_item.dart';

typedef OnDmSelectCallback = void Function(DmNarrow narrow);

class RecentDmConversationsPageBody extends StatefulWidget {
  const RecentDmConversationsPageBody({
    super.key,
    this.hideDmsIfUserCantPost = false,
    this.onDmSelect,
  });

  final bool hideDmsIfUserCantPost;
  final OnDmSelectCallback? onDmSelect;

  @override
  State<RecentDmConversationsPageBody> createState() =>
      _RecentDmConversationsPageBodyState();
}

class _RecentDmConversationsPageBodyState
    extends State<RecentDmConversationsPageBody> {
  RecentDmConversationsView? _model;
  Unreads? _unreadsModel;

  @override
  void initState() {
    super.initState();
    ever(StoreService.to.currentStore, (_) => _onStoreChanged());
    _initFromStore();
  }

  void _onStoreChanged() {
    _model?.removeListener(_modelChanged);
    _unreadsModel?.removeListener(_modelChanged);
    _initFromStore();
  }

  void _initFromStore() {
    _model = StoreService.to.requireStore.recentDmConversationsView
      ..addListener(_modelChanged);
    _unreadsModel = UnreadsService.to.unreads?..addListener(_modelChanged);
  }

  @override
  void dispose() {
    _model?.removeListener(_modelChanged);
    _unreadsModel?.removeListener(_modelChanged);
    super.dispose();
  }

  void _modelChanged() {
    setState(() {});
  }

  void _handleDmSelect(DmNarrow narrow) {
    if (widget.onDmSelect case final onDmSelect?) {
      onDmSelect(narrow);
    } else {
      Get.toNamed<dynamic>(
        AppRoutes.messageList,
        arguments: {'narrow': narrow},
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final zulipLocalizations = ZulipLocalizations.of(context);
    final sorted = _model?.sorted.toList() ?? <DmNarrow>[];

    if (sorted.isEmpty) {
      return PageBodyEmptyContentPlaceholder(
        header: zulipLocalizations.recentDmConversationsEmptyPlaceholderHeader,
        message:
            zulipLocalizations.recentDmConversationsEmptyPlaceholderMessage,
      );
    }

    return _DmConversationList(
      narrows: sorted.cast<DmNarrow>(),
      unreadsModel: _unreadsModel,
      hideDmsIfUserCantPost: widget.hideDmsIfUserCantPost,
      onDmSelect: _handleDmSelect,
    );
  }
}

class _DmConversationList extends StatelessWidget {
  const _DmConversationList({
    required this.narrows,
    required this.unreadsModel,
    required this.hideDmsIfUserCantPost,
    required this.onDmSelect,
  });

  final List<DmNarrow> narrows;
  final Unreads? unreadsModel;
  final bool hideDmsIfUserCantPost;
  final OnDmSelectCallback onDmSelect;

  @override
  Widget build(BuildContext context) {
    final store = requirePerAccountStore();
    final bottomInsets = MediaQuery.paddingOf(context).bottom;

    return SafeArea(
      bottom: false,
      child: ListView.builder(
        padding: EdgeInsets.only(bottom: bottomInsets + 90),
        itemCount: narrows.length,
        itemBuilder: (context, index) {
          final narrow = narrows[index];
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
          return RecentDmConversationsItem(
            narrow: narrow,
            unreadCount: unreadsModel?.countInDmNarrow(narrow) ?? 0,
            onDmSelect: onDmSelect,
          );
        },
      ),
    );
  }
}
