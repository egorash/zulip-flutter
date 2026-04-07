import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../generated/l10n/zulip_localizations.dart';
import '../../home_block/home.dart';
import '../../../values/icons.dart';
import '../../../values/theme.dart';
import 'main_menu.dart';
import 'package:salomon_bottom_bar/salomon_bottom_bar.dart';

class BottomNavBar extends StatelessWidget {
  const BottomNavBar({super.key, required this.tabNotifier});

  final Rx<HomePageTab> tabNotifier;

  int _getCurrentIndex() {
    final currentTab = tabNotifier.value;
    switch (currentTab) {
      case HomePageTab.channels:
        return 0;
      case HomePageTab.directMessages:
        return 1;
      case HomePageTab.inbox:
        return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final designVariables = DesignVariables.of(context);
    final zulipLocalizations = ZulipLocalizations.of(context);

    return Obx(
      () => Container(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: designVariables.borderBar)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SalomonBottomBar(
          currentIndex: _getCurrentIndex(),
          onTap: (int index) {
            switch (index) {
              case 0:
                tabNotifier.value = HomePageTab.channels;
              case 1:
                tabNotifier.value = HomePageTab.directMessages;
            }
          },
          backgroundColor: designVariables.bgBotBar,
          selectedItemColor: designVariables.icon,
          unselectedItemColor: designVariables.icon.withValues(alpha: 0.6),
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          itemPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,

          items: [
            SalomonBottomBarItem(
              icon: Icon(ZulipIcons.hash_italic),
              title: Text(
                zulipLocalizations.channelsPageTitle,
                style: const TextStyle(fontSize: 12),
              ),
              activeIcon: AnimatedScale(
                scale: 1.1,
                duration: const Duration(milliseconds: 200),
                child: Icon(ZulipIcons.hash_italic),
              ),
            ),
            SalomonBottomBarItem(
              icon: Icon(ZulipIcons.two_person),
              title: Text(
                zulipLocalizations.recentDmConversationsPageShortLabel,
                style: const TextStyle(fontSize: 12),
              ),
              activeIcon: AnimatedScale(
                scale: 1.1,
                duration: const Duration(milliseconds: 200),
                child: Icon(ZulipIcons.two_person),
              ),
            ),
            // SalomonBottomBarItem(
            //   icon: Icon(ZulipIcons.menu),
            //   title: Text(
            //     zulipLocalizations.navBarMenuLabel,
            //     style: const TextStyle(fontSize: 12),
            //   ),
            //   activeIcon: AnimatedScale(
            //     scale: 1.1,
            //     duration: const Duration(milliseconds: 200),
            //     child: Icon(ZulipIcons.menu),
            //   ),
            // ),
          ],
        ),
      ),
    );
  }
}

void showMainMenu(
  BuildContext context, {
  required Rx<HomePageTab> tabNotifier,
}) {
  final designVariables = DesignVariables.of(context);
  showModalBottomSheet<void>(
    context: context,
    clipBehavior: Clip.antiAlias,
    useSafeArea: true,
    isScrollControlled: true,
    backgroundColor: designVariables.bgBotBar,
    builder: (BuildContext _) {
      return MainMenu(tabNotifier: tabNotifier);
    },
  );
}
