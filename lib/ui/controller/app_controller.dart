import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../generated/l10n/zulip_localizations.dart';
import '../../get/app_pages.dart';
import '../../get/services/global_service.dart';
import '../../log.dart';
import '../../model/store.dart';
import '../utils/page.dart';
import '../widgets/dialog.dart';

class AppController extends GetxController {
  static AppController get to => Get.find<AppController>();

  final RxBool isReady = false.obs;
  final RxBool isLoading = true.obs;
  final Rx<GlobalStore?> globalStore = Rx<GlobalStore?>(null);

  final navigatorKey = GlobalKey<NavigatorState>();
  final navStackTracker = _TrackNavigationStack();

  static int _snackBarCount = 0;

  GlobalStore? get store => globalStore.value;

  @override
  void onInit() {
    super.onInit();
    _initialize();
  }

  Future<void> _initialize() async {
    isLoading.value = true;
    try {
      await GlobalService.to.initialize();
      globalStore.value = GlobalService.to.globalStore;
    } catch (e) {
      debugPrint('AppController initialization failed: $e');
    } finally {
      isLoading.value = false;
    }
  }

  String get initialRoute {
    final lastVisitedAccountId = globalStore.value?.lastVisitedAccount?.id;
    return lastVisitedAccountId != null ? AppRoutes.home : AppRoutes.addAccount;
  }

  void onSettingsChanged() {
    GlobalService.to.notifySettingsChanged();
  }

  void declareReady() {
    assert(navigatorKey.currentContext != null);
    isReady.value = true;
    reportErrorToUserBriefly = _reportErrorToUserBriefly;
    reportErrorToUserModally = _reportErrorToUserModally;
  }

  void _reportErrorToUserBriefly(String? message, {String? details}) {
    assert(isReady.value);

    if (message == null) {
      if (_snackBarCount == 0) return;
      scaffoldMessenger!.clearSnackBars();
      return;
    }

    final zulipLocalizations = ZulipLocalizations.of(
      navigatorKey.currentContext!,
    );
    final newSnackBar = scaffoldMessenger!.showSnackBar(
      snackBarAnimationStyle: AnimationStyle(
        duration: const Duration(milliseconds: 200),
        reverseDuration: const Duration(milliseconds: 50),
      ),
      SnackBar(
        content: Text(message),
        action: (details == null)
            ? null
            : SnackBarAction(
                label: zulipLocalizations.snackBarDetails,
                onPressed: () => showErrorDialog(
                  context: navigatorKey.currentContext!,
                  title: zulipLocalizations.errorDialogTitle,
                  message: details,
                ),
              ),
      ),
    );

    _snackBarCount++;
    newSnackBar.closed.whenComplete(() => _snackBarCount--);
  }

  void _reportErrorToUserModally(
    String title, {
    String? message,
    Uri? learnMoreButtonUrl,
  }) {
    assert(isReady.value);

    showErrorDialog(
      context: navigatorKey.currentContext!,
      title: title,
      message: message,
      learnMoreButtonUrl: learnMoreButtonUrl,
    );
  }

  void updateLastVisitedAccount(int accountId) {
    globalStore.value?.setLastVisitedAccount(accountId);
  }

  Future<NavigatorState> get navigator {
    final state = navigatorKey.currentState;
    if (state != null) return Future.value(state);

    assert(!isReady.value);
    final completer = Completer<NavigatorState>();
    ever(isReady, (value) {
      if (value) {
        assert(isReady.value);
        completer.complete(navigatorKey.currentState!);
      }
    });
    return completer.future;
  }

  ScaffoldMessengerState? get scaffoldMessenger {
    final context = navigatorKey.currentContext;
    if (context == null) return null;
    return ScaffoldMessenger.of(context);
  }

  @override
  void onClose() {
    globalStore.value = null;
    super.onClose();
  }
}

mixin NavigationStack {
  List<Route<dynamic>> get routes;

  int? get currentAccountId {
    for (final route in routes.reversed) {
      if (route case AccountPageRouteMixin(:final accountId)) {
        return accountId;
      }
    }
    return null;
  }

  PageRoute<dynamic>? get currentPageRoute {
    for (final route in routes.reversed) {
      switch (route) {
        case PageRoute():
          return route;
        case PopupRoute():
          continue;
        default:
          continue;
      }
    }
    return null;
  }
}

class _TrackNavigationStack extends NavigatorObserver with NavigationStack {
  @override
  final List<Route<dynamic>> routes = [];

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    assert(routes.lastOrNull == previousRoute);
    routes.add(route);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (routes.isNotEmpty && routes.lastOrNull == route) {
      routes.removeLast();
    }
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    final index = routes.lastIndexOf(route);
    if (index >= 0) {
      routes.removeAt(index);
    }
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    if (newRoute != null && oldRoute != null) {
      final index = routes.lastIndexOf(oldRoute);
      if (index >= 0) {
        routes[index] = newRoute;
      }
    }
  }
}
