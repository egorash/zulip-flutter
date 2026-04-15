import 'package:flutter/material.dart';

import '../../../api/model/model.dart';
import '../../../generated/l10n/zulip_localizations.dart';
import '../../../get/services/domains/users/users_service.dart';
import '../../../get/services/store_service.dart';
import '../../../model/narrow.dart';
import '../../utils/page.dart';
import '../../widgets/user.dart';
import '../profile_block/profile.dart';
import '../message_list_block/message_list_block.dart';

class GroupDmParticipantsPage extends StatelessWidget {
  const GroupDmParticipantsPage({super.key, required this.narrow});

  final DmNarrow narrow;

  static AccountRoute<void> buildRoute({
    int? accountId,
    BuildContext? context,
    required DmNarrow narrow,
  }) {
    return MaterialAccountWidgetRoute(
      accountId: accountId,
      context: context,
      page: GroupDmParticipantsPage(narrow: narrow),
    );
  }

  void _addParticipant(BuildContext context) {
    final store = requirePerAccountStore();
    final currentUserIds = narrow.allRecipientIds.toSet();

    showModalBottomSheet<void>(
      context: context,
      clipBehavior: Clip.antiAlias,
      useSafeArea: true,
      isScrollControlled: true,
      builder: (BuildContext context) => _AddParticipantSheet(
        currentUserIds: currentUserIds,
        onUserSelected: (userId) {
          final newUserIds = {
            ...narrow.allRecipientIds,
            userId,
          }.toList()..sort();
          final newNarrow = DmNarrow(
            allRecipientIds: newUserIds,
            selfUserId: store.selfUserId,
          );
          Navigator.of(context).pop();
          Navigator.of(context).pushReplacement(
            MessageListBlockPage.buildRoute(
              context: context,
              narrow: newNarrow,
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = requirePerAccountStore();
    final zulipLocalizations = ZulipLocalizations.of(context);
    final otherRecipientIds = narrow.otherRecipientIds;

    return Scaffold(
      appBar: AppBar(title: const Text('Participants')),
      body: ListView.builder(
        itemCount: otherRecipientIds.length,
        itemBuilder: (context, index) {
          final userId = otherRecipientIds[index];
          final user = store.getUser(userId);
          if (user == null) {
            return ListTile(title: Text(zulipLocalizations.unknownUserName));
          }
          return ListTile(
            leading: Avatar(userId: userId, size: 40, borderRadius: 4),
            title: Text(store.userDisplayName(userId)),
            subtitle:
                user.deliveryEmail != null && user.deliveryEmail!.isNotEmpty
                ? Text(user.deliveryEmail!)
                : null,
            onTap: () {
              Navigator.push(
                context,
                ProfilePage.buildRoute(context: context, userId: userId),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addParticipant(context),
        child: const Icon(Icons.person_add),
      ),
    );
  }
}

class _AddParticipantSheet extends StatefulWidget {
  final Set<int> currentUserIds;
  final void Function(int userId) onUserSelected;

  const _AddParticipantSheet({
    required this.currentUserIds,
    required this.onUserSelected,
  });

  @override
  State<_AddParticipantSheet> createState() => _AddParticipantSheetState();
}

class _AddParticipantSheetState extends State<_AddParticipantSheet> {
  late TextEditingController _searchController;
  List<User> _filteredUsers = [];

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController()
      ..addListener(_updateFilteredUsers);
    _updateFilteredUsers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _updateFilteredUsers() {
    final query = _searchController.text.toLowerCase();
    final allUsers = UsersService.to.allUsers.where(
      (user) => user.isActive && !widget.currentUserIds.contains(user.userId),
    );

    setState(() {
      _filteredUsers = allUsers
          .where((user) {
            if (query.isEmpty) return true;
            final nameMatch = user.fullName.toLowerCase().contains(query);
            final emailMatch =
                user.deliveryEmail?.toLowerCase().contains(query) ?? false;
            return nameMatch || emailMatch;
          })
          .take(20)
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                    hintText: 'Search users',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  autofocus: true,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: _filteredUsers.length,
            itemBuilder: (context, index) {
              final user = _filteredUsers[index];
              return ListTile(
                leading: Avatar(userId: user.userId, size: 40, borderRadius: 4),
                title: Text(UsersService.to.userDisplayName(user.userId)),
                subtitle:
                    user.deliveryEmail != null && user.deliveryEmail!.isNotEmpty
                    ? Text(user.deliveryEmail!)
                    : null,
                onTap: () => widget.onUserSelected(user.userId),
              );
            },
          ),
        ),
      ],
    );
  }
}
