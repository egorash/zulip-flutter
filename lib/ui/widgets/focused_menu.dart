import 'dart:ui';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../api/model/reaction.dart';
import '../../get/services/store_service.dart';
import '../../model/emoji.dart';
import '../../model/message_list.dart';
import '../blocks/message_list_block/widgets/message_list/messages_list_service.dart';
import '../extensions/color.dart';
import '../values/theme.dart';
import 'emoji.dart';

class FocusedMenuItem {
  Color? backgroundColor;
  Widget title;
  Widget? trailingIcon;
  Function onPressed;
  bool shouldPop;

  FocusedMenuItem({
    this.backgroundColor,
    required this.trailingIcon,
    required this.title,
    required this.onPressed,
    this.shouldPop = true,
  });
}

class FocusedMessageMenu extends StatefulWidget {
  final Widget child;
  final MessageListMessageItem item;
  final bool isMy;

  const FocusedMessageMenu({
    required this.child,
    required this.item,
    required this.isMy,
    super.key,
  });

  @override
  State<FocusedMessageMenu> createState() => _FocusedMessageMenuState();
}

class _FocusedMessageMenuState extends State<FocusedMessageMenu> {
  GlobalKey containerKey = GlobalKey();
  Offset childOffset = const Offset(0, 0);
  Size? childSize;

  void getOffset() {
    RenderBox renderBox =
        containerKey.currentContext!.findRenderObject() as RenderBox;
    Size size = renderBox.size;
    Offset offset = renderBox.localToGlobal(Offset.zero);
    setState(() {
      childOffset = Offset(offset.dx, offset.dy);
      childSize = size;
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: containerKey,
      onLongPress: () {
        HapticFeedback.lightImpact();
        openMenu(context);
      },
      onSecondaryTap: () {
        HapticFeedback.lightImpact();
        openMenu(context);
      },
      child: widget.child,
    );
  }

  Future<void> openMenu(BuildContext context) async {
    getOffset();
    await Navigator.push(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 50),
        pageBuilder: (context, animation, secondaryAnimation) {
          animation = Tween(begin: 0.0, end: 1.0).animate(animation);
          return GestureDetector(
            onTap: () => Get.back(),
            child: FadeTransition(
              opacity: animation,
              child: Builder(
                builder: (context) {
                  //RxBool isDeleting = false.obs;

                  return _FocusedMessageMenuDetails(
                    message: widget.item,
                    itemExtent: null,
                    menuBoxDecoration: null,
                    childOffset: childOffset,
                    childSize: childSize,
                    menuItems:
                        // isDeleting.value
                        //     ? <FocusedMenuItem>[
                        //         FocusedMenuItem(
                        //           title: Text(
                        //             'Удалить у всех',
                        //             // style: AppText.semibold14.copyWith(
                        //             //   color: AppColors.high,
                        //             // ),
                        //           ),
                        //           trailingIcon: null,
                        //           onPressed: () {
                        //             // Get.find<DialogController>().deleteMessage(
                        //             //   widget.model,
                        //             //   false,
                        //             // );
                        //           },
                        //         ),
                        //         FocusedMenuItem(
                        //           title: Text(
                        //             'Удалить у себя',
                        //             // style: AppText.semibold14.copyWith(
                        //             //   color: AppColors.high,
                        //             // ),
                        //           ),
                        //           trailingIcon: null,
                        //           onPressed: () {
                        //             // Get.find<DialogController>().deleteMessage(
                        //             //   widget.model,
                        //             //   true,
                        //             // );
                        //           },
                        //         ),
                        //       ]
                        //     :
                        <FocusedMenuItem>[
                          FocusedMenuItem(
                            title: Text(
                              'Ответить',
                              // style: AppText.semibold14.copyWith(
                              //   color: AppColors.high,
                              // ),
                            ),
                            trailingIcon: Icon(Icons.question_answer),
                            onPressed: () {
                              MessagesListService.answerMessage(widget.item);
                            },
                          ),
                          FocusedMenuItem(
                            title: Text(
                              'Копировать',
                              // style: AppText.semibold14.copyWith(
                              //   color: AppColors.high,
                              // ),
                            ),
                            trailingIcon: Icon(Icons.copy),
                            onPressed: () {
                              MessagesListService.copyMessage(widget.item);
                            },
                          ),
                          FocusedMenuItem(
                            title: Text(
                              'Копировать ссылку',
                              // style: AppText.semibold14.copyWith(
                              //   color: AppColors.high,
                              // ),
                            ),
                            trailingIcon: Icon(Icons.link),
                            onPressed: () {
                              MessagesListService.copyMessageLink(widget.item);
                            },
                          ),
                          if (MessagesListService.getShouldShowEditButton(
                            widget.item,
                          ))
                            FocusedMenuItem(
                              title: Text(
                                'Изменить',
                                // style: AppText.semibold14.copyWith(
                                //   color: AppColors.high,
                                // ),
                              ),
                              trailingIcon: Icon(Icons.edit),
                              onPressed: () {
                                MessagesListService.editMessage(widget.item);
                              },
                            ),
                          // FocusedMenuItem(
                          //   title: Text(
                          //     'Удалить',
                          //     // style: AppText.semibold14
                          //     //     .copyWith(color: AppColors.high),
                          //   ),
                          //   trailingIcon: Icon(Icons.delete),
                          //   onPressed: () {
                          //     isDeleting.value = true;
                          //     setState(() {});
                          //   },
                          //   shouldPop: false,
                          // ),
                        ],
                    blurSize: 20,
                    menuWidth: 200,
                    blurBackgroundColor: Colors.black54,
                    bottomOffsetHeight: 100,
                    menuOffset: 8,
                    isLeftPos: !widget.isMy,
                    child: widget.child,
                  );
                },
              ),
            ),
          );
        },
        fullscreenDialog: true,
        opaque: false,
      ),
    );
  }
}

class _FocusedMessageMenuDetails extends StatelessWidget {
  final List<FocusedMenuItem> menuItems;
  final MessageListMessageItem message;
  final BoxDecoration? menuBoxDecoration;
  final Offset childOffset;
  final double? itemExtent;
  final Size? childSize;
  final Widget child;
  final double? blurSize;
  final double? menuWidth;
  final Color? blurBackgroundColor;
  final double? bottomOffsetHeight;
  final double? menuOffset;
  final bool? isLeftPos;

  const _FocusedMessageMenuDetails({
    required this.menuItems,
    required this.message,
    required this.child,
    required this.childOffset,
    required this.childSize,
    required this.menuBoxDecoration,
    required this.itemExtent,
    required this.blurSize,
    required this.blurBackgroundColor,
    required this.menuWidth,
    required this.isLeftPos,
    this.bottomOffsetHeight,
    this.menuOffset,
  });

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    final emojiHeight = 44;

    final maxMenuHeight = emojiHeight + size.height * 0.45;
    final listHeight =
        menuItems.length * (itemExtent ?? 41.0) + (menuItems.length - 1) * 8;

    final maxMenuWidth = menuWidth ?? (size.width * 0.70);
    final menuHeight =
        (listHeight < maxMenuHeight ? listHeight : maxMenuHeight) +
        16 +
        emojiHeight;
    final isLeft = isLeftPos ?? (childOffset.dx + maxMenuWidth) < size.width;
    final leftOffset = isLeft
        ? childOffset.dx
        : (childOffset.dx - maxMenuWidth + childSize!.width);
    final isBottom =
        (childOffset.dy + menuHeight + childSize!.height) <
        (size.height - bottomOffsetHeight!);
    final topOffset = isBottom
        ? childOffset.dy + childSize!.height + menuOffset!
        : childOffset.dy - menuHeight - menuOffset!;

    return Scaffold(
      backgroundColor: const Color.fromRGBO(0, 0, 0, 0),
      body: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          GestureDetector(
            onTap: () {
              Navigator.pop(context);
            },
            child: BackdropFilter(
              filter: ImageFilter.blur(
                sigmaX: blurSize ?? 4,
                sigmaY: blurSize ?? 4,
              ),
              child: Container(
                color: (blurBackgroundColor ?? Colors.black).withValues(
                  alpha: 0.7,
                ),
              ),
            ),
          ),
          Positioned(
            top: topOffset,
            left: leftOffset,
            child: TweenAnimationBuilder(
              duration: const Duration(milliseconds: 200),
              builder: (BuildContext context, double value, Widget? child) {
                return Transform.scale(
                  scale: value,
                  alignment: Alignment.center,
                  child: child,
                );
              },
              tween: Tween(begin: 0.0, end: 1.0),
              child: SizedBox(
                height: menuHeight,
                child: Column(
                  children: [
                    Container(
                      height: 40,
                      margin: EdgeInsets.only(bottom: 4),
                      width: maxMenuWidth,
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: EmojiRow(message: message),
                    ),
                    Container(
                      width: maxMenuWidth,
                      height: menuHeight - emojiHeight,
                      padding: const EdgeInsets.symmetric(
                        vertical: 8,
                        horizontal: 16,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: ListView.separated(
                        itemCount: menuItems.length,
                        padding: EdgeInsets.zero,
                        physics: const BouncingScrollPhysics(),
                        itemBuilder: (context, index) {
                          FocusedMenuItem item = menuItems[index];

                          return _FocusedMenuCard(item: item);
                        },
                        separatorBuilder: (context, index) => Container(
                          height: 8,
                          width: double.infinity,
                          decoration: const BoxDecoration(
                            border: Border(top: BorderSide(color: Colors.grey)),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: childOffset.dy,
            left: childOffset.dx,
            child: AbsorbPointer(
              absorbing: true,
              child: SizedBox(
                width: childSize!.width,
                height: childSize!.height,
                child: child,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class FocusedMenu extends StatefulWidget {
  final Widget child;
  final double? menuItemExtent;
  final double? menuWidth;
  final List<FocusedMenuItem> menuItems;
  final BoxDecoration? menuBoxDecoration;
  final Duration? duration;
  final double? blurSize;
  final Color? blurBackgroundColor;
  final double? bottomOffsetHeight;
  final double? menuOffset;
  final bool? isLeftPos;
  final bool enableTap;
  final bool enableLongTap;
  final bool enableSecondaryTap;

  const FocusedMenu({
    super.key,
    required this.child,
    required this.menuItems,
    this.duration,
    this.menuBoxDecoration,
    this.menuItemExtent,
    this.blurSize,
    this.blurBackgroundColor,
    this.menuWidth,
    this.bottomOffsetHeight,
    this.menuOffset,
    this.isLeftPos,
    this.enableTap = false,
    this.enableLongTap = false,
    this.enableSecondaryTap = false,
  });

  @override
  FocusedMenuState createState() => FocusedMenuState();
}

class FocusedMenuState extends State<FocusedMenu> {
  GlobalKey containerKey = GlobalKey();
  Offset childOffset = const Offset(0, 0);
  Size? childSize;

  void getOffset() {
    RenderBox renderBox =
        containerKey.currentContext!.findRenderObject() as RenderBox;
    Size size = renderBox.size;
    Offset offset = renderBox.localToGlobal(Offset.zero);
    setState(() {
      childOffset = Offset(offset.dx, offset.dy);
      childSize = size;
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: containerKey,
      onTap: widget.enableTap
          ? () {
              openMenu(context);
            }
          : null,
      onLongPress: widget.enableLongTap
          ? () {
              openMenu(context);
            }
          : null,
      onSecondaryTap: widget.enableSecondaryTap
          ? () {
              openMenu(context);
            }
          : null,
      child: widget.child,
    );
  }

  Future<void> openMenu(BuildContext context) async {
    getOffset();
    await Navigator.push(
      context,
      PageRouteBuilder(
        transitionDuration:
            widget.duration ?? const Duration(milliseconds: 100),
        pageBuilder: (context, animation, secondaryAnimation) {
          animation = Tween(begin: 0.0, end: 1.0).animate(animation);
          return FadeTransition(
            opacity: animation,
            child: _FocusedMenuDetails(
              itemExtent: widget.menuItemExtent,
              menuBoxDecoration: widget.menuBoxDecoration,
              childOffset: childOffset,
              childSize: childSize,
              menuItems: widget.menuItems,
              blurSize: widget.blurSize,
              menuWidth: widget.menuWidth,
              blurBackgroundColor: widget.blurBackgroundColor,
              bottomOffsetHeight: widget.bottomOffsetHeight ?? 0,
              menuOffset: widget.menuOffset ?? 0,
              isLeftPos: widget.isLeftPos,
              child: widget.child,
            ),
          );
        },
        fullscreenDialog: true,
        opaque: false,
      ),
    );
  }
}

class _FocusedMenuDetails extends StatelessWidget {
  final List<FocusedMenuItem> menuItems;
  final BoxDecoration? menuBoxDecoration;
  final Offset childOffset;
  final double? itemExtent;
  final Size? childSize;
  final Widget child;
  final double? blurSize;
  final double? menuWidth;
  final Color? blurBackgroundColor;
  final double? bottomOffsetHeight;
  final double? menuOffset;
  final bool? isLeftPos;

  const _FocusedMenuDetails({
    required this.menuItems,
    required this.child,
    required this.childOffset,
    required this.childSize,
    required this.menuBoxDecoration,
    required this.itemExtent,
    required this.blurSize,
    required this.blurBackgroundColor,
    required this.menuWidth,
    required this.isLeftPos,
    this.bottomOffsetHeight,
    this.menuOffset,
  });

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;

    final maxMenuHeight = size.height * 0.45;
    final listHeight =
        menuItems.length * (itemExtent ?? 41.0) + (menuItems.length - 1) * 8;

    final maxMenuWidth = menuWidth ?? (size.width * 0.70);
    final menuHeight =
        (listHeight < maxMenuHeight ? listHeight : maxMenuHeight) + 16;
    final isLeft = isLeftPos ?? (childOffset.dx + maxMenuWidth) < size.width;
    final leftOffset = isLeft
        ? childOffset.dx
        : (childOffset.dx - maxMenuWidth + childSize!.width);
    final isBottom =
        (childOffset.dy + menuHeight + childSize!.height) <
        (size.height - bottomOffsetHeight!);
    final topOffset = isBottom
        ? childOffset.dy + childSize!.height + menuOffset!
        : childOffset.dy - menuHeight - menuOffset!;
    return Scaffold(
      backgroundColor: const Color.fromRGBO(0, 0, 0, 0),
      body: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          GestureDetector(
            onTap: () {
              Navigator.pop(context);
            },
            child: BackdropFilter(
              filter: ImageFilter.blur(
                sigmaX: blurSize ?? 4,
                sigmaY: blurSize ?? 4,
              ),
              child: Container(
                color: (blurBackgroundColor ?? Colors.black).withValues(
                  alpha: 0.7,
                ),
              ),
            ),
          ),
          Positioned(
            top: topOffset,
            left: leftOffset,
            child: TweenAnimationBuilder(
              duration: const Duration(milliseconds: 200),
              builder: (BuildContext context, double value, Widget? child) {
                return Transform.scale(
                  scale: value,
                  alignment: Alignment.center,
                  child: child,
                );
              },
              tween: Tween(begin: 0.0, end: 1.0),
              child: Container(
                width: maxMenuWidth,
                height: menuHeight,
                padding: const EdgeInsets.symmetric(
                  vertical: 8,
                  horizontal: 16,
                ),
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ListView.separated(
                  itemCount: menuItems.length,
                  padding: EdgeInsets.zero,
                  physics: const BouncingScrollPhysics(),
                  itemBuilder: (context, index) {
                    FocusedMenuItem item = menuItems[index];

                    return _FocusedMenuCard(item: item);
                  },
                  separatorBuilder: (context, index) => Container(
                    height: 8,
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      border: Border(top: BorderSide(color: Colors.grey)),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: childOffset.dy,
            left: childOffset.dx,
            child: AbsorbPointer(
              absorbing: true,
              child: SizedBox(
                width: childSize!.width,
                height: childSize!.height,
                child: child,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FocusedMenuCard extends StatelessWidget {
  final FocusedMenuItem item;
  const _FocusedMenuCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (item.shouldPop) {
          Navigator.pop(context);
        }
        item.onPressed();
      },
      child: Container(
        alignment: Alignment.center,
        margin: const EdgeInsets.only(bottom: 1),
        color: item.backgroundColor ?? Colors.black,
        height: 41,
        child: Row(
          spacing: 6,
          children: <Widget>[
            if (item.trailingIcon != null) ...[item.trailingIcon!],
            item.title,
          ],
        ),
      ),
    );
  }
}

class EmojiRow extends StatelessWidget {
  final MessageListMessageItem message;

  const EmojiRow({super.key, required this.message});

  bool hasSelfVote(EmojiCandidate emoji) {
    final store = requirePerAccountStore();
    return message.message.reactions?.aggregated.any((reactionWithVotes) {
          return reactionWithVotes.reactionType == ReactionType.unicodeEmoji &&
              reactionWithVotes.emojiCode == emoji.emojiCode &&
              reactionWithVotes.userIds.contains(store.selfUserId);
        }) ??
        false;
  }

  Widget _buildButton({
    required BuildContext context,
    required EmojiCandidate emoji,
    required bool isSelfVoted,
    required bool isFirst,
  }) {
    final designVariables = DesignVariables.of(context);
    return Flexible(
      child: InkWell(
        onTap: () {
          MessagesListService.addOrRemoveReaction(
            isSelfVoted: isSelfVoted,
            messageId: message.message.id,
            emoji: emoji,
          );
          Get.back();
        },
        splashFactory: NoSplash.splashFactory,
        borderRadius: isFirst
            ? const BorderRadiusDirectional.only(
                topStart: Radius.circular(7),
              ).resolve(Directionality.of(context))
            : null,
        overlayColor: WidgetStateColor.resolveWith(
          (states) => states.any((e) => e == WidgetState.pressed)
              ? designVariables.contextMenuItemBg.withFadedAlpha(0.20)
              : Colors.transparent,
        ),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 5),
          alignment: Alignment.center,

          decoration: BoxDecoration(
            color: isSelfVoted
                ? designVariables.contextMenuItemBg.withFadedAlpha(0.20)
                : null,
            shape: BoxShape.circle,
          ),
          child: UnicodeEmojiWidget(
            emojiDisplay: emoji.emojiDisplay as UnicodeEmojiDisplay,
            size: 20,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = requirePerAccountStore();
    final popularEmojiCandidates = store.popularEmojiCandidates();
    // final zulipLocalizations = ZulipLocalizations.of(context);
    // final designVariables = DesignVariables.of(context);

    return Row(
      children: [
        Flexible(
          child: Row(
            spacing: 1,
            children: List.unmodifiable(
              popularEmojiCandidates.mapIndexed(
                (index, emoji) => _buildButton(
                  context: context,
                  emoji: emoji,
                  isSelfVoted: hasSelfVote(emoji),
                  isFirst: index == 0,
                ),
              ),
            ),
          ),
        ),
        // InkWell(
        //   onTap: () {},
        //   splashFactory: NoSplash.splashFactory,
        //   borderRadius: const BorderRadiusDirectional.only(
        //     topEnd: Radius.circular(7),
        //   ).resolve(TextDirection.ltr),
        //   overlayColor: WidgetStateColor.resolveWith(
        //     (states) => states.any((e) => e == WidgetState.pressed)
        //         ? designVariables.contextMenuItemBg.withFadedAlpha(0.20)
        //         : Colors.transparent,
        //   ),
        //   child: Container(
        //     height: 24,
        //     width: 24,
        //     alignment: Alignment.center,
        //     decoration: BoxDecoration(
        //       shape: BoxShape.circle,
        //       color: Colors.white30,
        //     ),
        //     child: Icon(
        //       ZulipIcons.chevron_right,
        //       color: designVariables.contextMenuItemText,
        //       size: 20,
        //     ),
        //   ),
        // ),

      ],
    );
  }
}
