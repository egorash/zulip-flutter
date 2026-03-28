import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:get/get.dart';

import '../generated/l10n/zulip_localizations.dart';
import '../get/app_pages.dart';
import '../get/services/global_service.dart';
import '../model/localizations.dart';
import '../model/store.dart';
import 'controller/app_controller.dart';
import 'widgets/about_zulip.dart';
import 'widgets/dialog.dart';
import 'blocks/home_block/home.dart';
import 'blocks/login_block/login.dart';
import 'utils/page.dart';
import 'values/theme.dart';

class ZulipApp extends StatelessWidget {
  const ZulipApp({super.key, this.navigatorObservers});

  final List<NavigatorObserver>? navigatorObservers;

  static RxBool get ready => AppController.to.isReady;

  static Future<NavigatorState> get navigator => AppController.to.navigator;

  static ScaffoldMessengerState? get scaffoldMessenger =>
      AppController.to.scaffoldMessenger;

  static NavigationStack? get navigationStack =>
      AppController.to.navStackTracker;

  @visibleForTesting
  static void debugReset() {
    // TODO: implement reset
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<AppController>(
      init: AppController(),
      builder: (controller) {
        return Obx(() {
          if (controller.isLoading.value) {
            return MaterialApp(
              theme: zulipThemeData(context),
              home: Scaffold(body: Center(child: CircularProgressIndicator())),
            );
          }

          final globalStore = controller.globalStore.value;
          if (globalStore == null) {
            return MaterialApp(
              theme: zulipThemeData(context),
              home: Scaffold(body: Center(child: Text('Failed to initialize'))),
            );
          }

          return Obx(() {
            GlobalService.to.settingsChanged.value;
            return GetMaterialApp(
              onGenerateTitle: (BuildContext context) {
                return ZulipLocalizations.of(context).zulipAppTitle;
              },
              localizationsDelegates: ZulipLocalizations.localizationsDelegates,
              supportedLocales: ZulipLocalizations.supportedLocales,
              theme: zulipThemeData(context),
              initialBinding: InitialBinding(),
              getPages: AppPages.pages,

              initialRoute: controller.initialRoute,
              navigatorKey: controller.navigatorKey,
              navigatorObservers: [
                ...?navigatorObservers,
                _PreventEmptyStack(controller: controller),
                controller.navStackTracker,
                _UpdateLastVisitedAccount(globalStore),
              ],
              builder: (BuildContext context, Widget? child) {
                if (!controller.isReady.value) {
                  SchedulerBinding.instance.addPostFrameCallback(
                    (_) => controller.declareReady(),
                  );
                }
                GlobalLocalizations.zulipLocalizations = ZulipLocalizations.of(
                  context,
                );
                return child!;
              },
              onGenerateRoute: (_) => null,
            );
          });
        });
      },
    );
  }
}

class _PreventEmptyStack extends NavigatorObserver {
  _PreventEmptyStack({required this.controller});

  final AppController controller;

  void _pushRouteIfEmptyStack() async {
    final navigator = await controller.navigator;
    bool isEmptyStack = true;
    navigator.popUntil((route) {
      isEmptyStack = false;
      return true;
    });
    if (isEmptyStack) {
      unawaited(
        navigator.push(MaterialWidgetRoute(page: const ChooseAccountPage())),
      );
    }
  }

  @override
  void didRemove(Route<void> route, Route<void>? previousRoute) {
    _pushRouteIfEmptyStack();
  }

  @override
  void didPop(Route<void> route, Route<void>? previousRoute) {
    _pushRouteIfEmptyStack();
  }
}

class _UpdateLastVisitedAccount extends NavigatorObserver {
  _UpdateLastVisitedAccount(this.globalStore);

  final GlobalStore globalStore;

  @override
  void didChangeTop(Route<void> topRoute, _) {
    if (topRoute case AccountPageRouteMixin(:var accountId)) {
      globalStore.setLastVisitedAccount(accountId);
    }
  }
}

class ChooseAccountPage extends StatelessWidget {
  const ChooseAccountPage({super.key});

  Widget _buildAccountItem(
    BuildContext context, {
    required int accountId,
    required Widget title,
    Widget? subtitle,
  }) {
    final colorScheme = ColorScheme.of(context);
    final designVariables = DesignVariables.of(context);
    final zulipLocalizations = ZulipLocalizations.of(context);
    final materialLocalizations = MaterialLocalizations.of(context);
    return Card(
      clipBehavior: Clip.hardEdge,
      child: ListTile(
        title: title,
        subtitle: subtitle,
        tileColor: colorScheme.secondaryContainer,
        textColor: colorScheme.onSecondaryContainer,
        trailing: MenuAnchor(
          menuChildren: [
            MenuItemButton(
              onPressed: () async {
                final dialog = showSuggestedActionDialog(
                  context: context,
                  title: zulipLocalizations.logOutConfirmationDialogTitle,
                  message: zulipLocalizations.logOutConfirmationDialogMessage,
                  destructiveActionButton: true,
                  actionButtonText:
                      zulipLocalizations.logOutConfirmationDialogConfirmButton,
                );
                if (await dialog.result == true) {
                  if (!context.mounted) return;
                  unawaited(GlobalService.to.logOutAccount(accountId));
                }
              },
              child: Text(zulipLocalizations.chooseAccountPageLogOutButton),
            ),
          ],
          builder:
              (BuildContext context, MenuController controller, Widget? child) {
                return IconButton(
                  tooltip: materialLocalizations.showMenuTooltip,
                  onPressed: () {
                    if (controller.isOpen) {
                      controller.close();
                    } else {
                      controller.open();
                    }
                  },
                  icon: Icon(Icons.adaptive.more, color: designVariables.icon),
                );
              },
        ),
        contentPadding: const EdgeInsetsDirectional.only(start: 16, end: 12),
        onTap: () => HomePage.navigate(context, accountId: accountId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.of(context);
    final zulipLocalizations = ZulipLocalizations.of(context);
    final globalStore = GlobalService.to.globalStore;
    if (globalStore == null) return const SizedBox.shrink();

    final hasBackButton =
        ModalRoute.of(context)?.impliesAppBarDismissal ?? false;

    return MenuButtonTheme(
      data: MenuButtonThemeData(
        style: MenuItemButton.styleFrom(
          backgroundColor: colorScheme.secondaryContainer,
          foregroundColor: colorScheme.onSecondaryContainer,
        ),
      ),
      child: Scaffold(
        appBar: AppBar(
          titleSpacing: hasBackButton ? null : 16,
          title: Text(zulipLocalizations.chooseAccountPageTitle),
          actions: const [ChooseAccountPageOverflowButton()],
        ),
        body: SafeArea(
          minimum: const EdgeInsets.fromLTRB(8, 0, 8, 8),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.only(top: 8),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          for (final (:accountId, :account)
                              in globalStore.accountEntries)
                            _buildAccountItem(
                              context,
                              accountId: accountId,
                              title: Text(account.realmUrl.toString()),
                              subtitle: Text(account.email),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () =>
                        Navigator.push(context, AddAccountPage.buildRoute()),
                    child: Text(
                      zulipLocalizations.chooseAccountButtonAddAnAccount,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class ChooseAccountPageOverflowButton extends StatelessWidget {
  const ChooseAccountPageOverflowButton({super.key});

  @override
  Widget build(BuildContext context) {
    final zulipLocalizations = ZulipLocalizations.of(context);
    final materialLocalizations = MaterialLocalizations.of(context);
    return MenuAnchor(
      menuChildren: [
        MenuItemButton(
          onPressed: () {
            Navigator.push(context, AboutZulipPage.buildRoute(context));
          },
          child: Text(zulipLocalizations.aboutPageTitle),
        ),
      ],
      builder:
          (BuildContext context, MenuController controller, Widget? child) {
            return IconButton(
              tooltip: materialLocalizations.showMenuTooltip,
              onPressed: () {
                if (controller.isOpen) {
                  controller.close();
                } else {
                  controller.open();
                }
              },
              icon: Icon(Icons.adaptive.more),
            );
          },
    );
  }
}
