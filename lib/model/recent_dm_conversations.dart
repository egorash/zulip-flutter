import 'dart:math';
import 'dart:developer' as developer;

import 'package:collection/collection.dart';
import 'package:get/get.dart';

import '../api/core.dart';
import 'binding.dart';
import 'store.dart';
import '../api/model/initial_snapshot.dart';
import '../api/model/model.dart';
import '../api/model/events.dart';
import '../api/route/messages.dart';
import 'narrow.dart';

class RecentDmConversationsView extends GetxController {
  factory RecentDmConversationsView({
    required CorePerAccountStore core,
    required List<RecentDmConversation> initial,
  }) {
    final entries =
        initial
            .map(
              (conversation) => MapEntry(
                DmNarrow.ofRecentDmConversation(
                  conversation,
                  selfUserId: core.selfUserId,
                ),
                conversation.maxMessageId,
              ),
            )
            .toList()
          ..sort((a, b) => -a.value.compareTo(b.value));

    final latestMessagesByRecipient = <int, int>{};
    for (final entry in entries) {
      final dmNarrow = entry.key;
      final maxMessageId = entry.value;
      for (final userId in dmNarrow.otherRecipientIds) {
        latestMessagesByRecipient.putIfAbsent(userId, () => maxMessageId);
      }
    }

    return RecentDmConversationsView._(
      core: core,
      map: Map.fromEntries(entries),
      sorted: QueueList.from(entries.map((e) => e.key)),
      latestMessagesByRecipient: latestMessagesByRecipient,
    );
  }

  RecentDmConversationsView._({
    required CorePerAccountStore core,
    required Map<DmNarrow, int> map,
    required QueueList<DmNarrow> sorted,
    required Map<int, int> latestMessagesByRecipient,
  }) : _core = core,
       _accountId = core.accountId,
       _map = Rx(map),
       _sorted = Rx(sorted),
       _latestMessagesByRecipient = Rx(latestMessagesByRecipient),
       _latestMessages = Rx({});

  final CorePerAccountStore _core;
  final int _accountId;

  CorePerAccountStore get core => _core;

  int get selfUserId => _core.selfUserId;

  ApiConnection get connection => _core.connection;

  @override
  void onInit() {
    super.onInit();
    prefetchLastMessages();
  }

  @override
  void onReady() {
    // TODO: implement onReady
    super.onReady();
  }

  final Rx<Map<DmNarrow, int>> _map;
  Map<DmNarrow, int> get map => _map.value;

  final Rx<QueueList<DmNarrow>> _sorted;
  QueueList<DmNarrow> get sorted => _sorted.value;

  final Rx<Map<int, int>> _latestMessagesByRecipient;
  Map<int, int> get latestMessagesByRecipient =>
      _latestMessagesByRecipient.value;

  final Rx<Map<DmNarrow, Message?>> _latestMessages;
  Map<DmNarrow, Message?> get latestMessages => _latestMessages.value;

  void _insertSorted(DmNarrow key, int msgId) {
    final i = _sorted.value.indexWhere((k) => _map.value[k]! < msgId);
    switch (i) {
      case == 0:
        _sorted.value.addFirst(key);
      case < 0:
        _sorted.value.addLast(key);
      default:
        _sorted.value.insert(i, key);
    }
    _sorted.refresh();
  }

  void handleMessageEvent(MessageEvent event) {
    final message = event.message;
    if (message is! DmMessage) {
      return;
    }
    final key = DmNarrow.ofMessage(message, selfUserId: selfUserId);

    final prev = _map.value[key];
    if (prev == null) {
      _map.value[key] = message.id;
      _insertSorted(key, message.id);
    } else if (prev >= message.id) {
      // Do nothing
    } else {
      _map.value[key] = message.id;

      final i = _sorted.value.indexOf(key);
      if (i != 0) {
        _sorted.value.removeAt(i);
        _insertSorted(key, message.id);
      }
    }

    for (final recipient in key.otherRecipientIds) {
      final existing = _latestMessagesByRecipient.value[recipient];
      _latestMessagesByRecipient.value[recipient] = existing != null
          ? max(message.id, existing)
          : message.id;
    }
    _latestMessagesByRecipient.refresh();
  }

  Future<void> prefetchLastMessages() async {
    final conn = connection;

    final globalStore = ZulipBinding.instance.getGlobalStoreSync();
    if (globalStore == null) {
      return;
    }

    final store = await globalStore.perAccount(_accountId);

    for (final entry in _map.value.entries) {
      final narrow = entry.key;

      try {
        final result = await getMessages(
          conn,
          narrow: narrow.apiEncode(),
          anchor: const NumericAnchor(0),
          numBefore: 0,
          numAfter: 1,
          allowEmptyTopicName: true,
        );
        store.reconcileMessages(result.messages);
        if (result.messages.isNotEmpty) {
          developer.log(
            'prefetchLastMessages: got ${result.messages.length} messages for narrow $narrow',
            name: 'RecentDmConversations',
          );
          final newMessages = Map<DmNarrow, Message?>.from(
            _latestMessages.value,
          );
          newMessages[narrow] = result.messages.first;
          _latestMessages.value = newMessages;
        } else {
          developer.log(
            'prefetchLastMessages: no messages for narrow $narrow',
            name: 'RecentDmConversations',
          );
        }
      } catch (e) {
        developer.log(
          'prefetchLastMessages error: $e',
          name: 'RecentDmConversations',
        );
      }
    }

    developer.log(
      'prefetchLastMessages: calling refresh, latestMessages count: ${_latestMessages.value.length}',
      name: 'RecentDmConversations',
    );
    refresh();
  }
}
