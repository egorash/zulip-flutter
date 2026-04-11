import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../api/model/reaction.dart';
import '../../get/services/store_service.dart';
import '../../model/emoji.dart';
import '../../model/message_list.dart';
import '../../model/store.dart';
import '../blocks/message_list_block/widgets/message_list/messages_list_service.dart';
import '../extensions/color.dart';
import '../values/icons.dart';
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
                              style: TextStyle(fontSize: 16),
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
                              style: TextStyle(fontSize: 16),
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
                              style: TextStyle(fontSize: 14),
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
                                style: TextStyle(fontSize: 16),
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

class _FocusedMessageMenuDetails extends StatefulWidget {
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
  State<_FocusedMessageMenuDetails> createState() =>
      _FocusedMessageMenuDetailsState();
}

class _FocusedMessageMenuDetailsState
    extends State<_FocusedMessageMenuDetails> {
  bool _showActionButtons = true;

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    final emojiHeight = 52.0;

    final maxMenuHeight = size.height * 0.45;
    final listHeight =
        widget.menuItems.length * (widget.itemExtent ?? 48.0) +
        (widget.menuItems.length - 1) * 8;

    final maxMenuWidth = widget.menuWidth ?? (size.width * 0.70);
    final menuHeight =
        (listHeight < maxMenuHeight ? listHeight : maxMenuHeight) + 16;
    final isLeft =
        widget.isLeftPos ?? (widget.childOffset.dx + maxMenuWidth) < size.width;
    final leftOffset = isLeft
        ? widget.childOffset.dx
        : (widget.childOffset.dx - maxMenuWidth + widget.childSize!.width);

    final addictionalHeight =
        (widget.childOffset.dy + maxMenuHeight) > size.height
        ? size.height - (widget.childOffset.dy + maxMenuHeight)
        : 0;

    final topOffset =
        widget.childOffset.dy +
        widget.childSize!.height +
        widget.menuOffset! +
        emojiHeight +
        addictionalHeight;

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
                sigmaX: widget.blurSize ?? 4,
                sigmaY: widget.blurSize ?? 4,
              ),
              child: Container(
                color: (widget.blurBackgroundColor ?? Colors.black).withValues(
                  alpha: 0.7,
                ),
              ),
            ),
          ),
          if (_showActionButtons)
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
                      itemCount: widget.menuItems.length,
                      padding: EdgeInsets.zero,
                      physics: const BouncingScrollPhysics(),
                      itemBuilder: (context, index) {
                        FocusedMenuItem item = widget.menuItems[index];

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
            ),
          Positioned(
            top: widget.childOffset.dy + addictionalHeight,
            left: widget.childOffset.dx,
            child: Column(
              crossAxisAlignment: isLeft
                  ? CrossAxisAlignment.start
                  : CrossAxisAlignment.end,
              children: [
                Container(
                  margin: EdgeInsets.only(bottom: 4, left: 12, right: 12),
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(32),
                  ),
                  child: EmojiRow(
                    message: widget.message,
                    onExpand: () => setState(() {
                      _showActionButtons = false;
                    }),
                    isExpanded: !_showActionButtons,
                  ),
                ),
                AbsorbPointer(
                  absorbing: true,
                  child: SizedBox(
                    width: widget.childSize!.width,
                    height: widget.childSize!.height,
                    child: widget.child,
                  ),
                ),
              ],
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
    FocusManager.instance.primaryFocus?.unfocus();
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
        menuItems.length * (itemExtent ?? 48.0) + (menuItems.length - 1) * 8;

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
      behavior: HitTestBehavior.translucent,
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
        height: 48,
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
  final VoidCallback onExpand;
  final bool isExpanded;
  const EmojiRow({
    super.key,
    required this.message,
    required this.onExpand,
    required this.isExpanded,
  });

  // List<EmojiCandidate> _getCatigories(PerAccountStore store) {
  //   final cat = store.emoji
  //   return [];
  // }

  List<EmojiCandidate> _getPopularEmojis(PerAccountStore store) {
    return isExpanded
        ? store.groupEmojis().values.expand((v) => v).toList()
        : store.popularEmojiCandidates().take(6).toList();
  }

  List<EmojiSection> _getAllEmojis(PerAccountStore store) {
    return store
        .groupEmojis()
        .entries
        .map((e) => EmojiSection(e.key, e.value))
        .toList();
  }

  bool _hasSelfVote(EmojiCandidate emoji) {
    final store = requirePerAccountStore();
    return message.message.reactions?.aggregated.any(
          (r) =>
              r.reactionType == ReactionType.unicodeEmoji &&
              r.emojiCode == emoji.emojiCode &&
              r.userIds.contains(store.selfUserId),
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    final store = requirePerAccountStore();
    final designVariables = DesignVariables.of(context);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.fastOutSlowIn,
      width: 320,
      height: isExpanded ? 250 : 50,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: designVariables.background,
        borderRadius: BorderRadius.circular(isExpanded ? 20 : 30),
      ),
      child: ClipRect(
        child: !isExpanded
            ? Row(
                spacing: 4,
                children: [
                  ..._getPopularEmojis(
                    store,
                  ).take(6).map((emoji) => _buildEmojiItem(emoji, context)),
                  _buildExpandButton(),
                ],
              )
            : EmojiPickerGrid(
                sections: _getAllEmojis(store),
                itemBuilder: (emoji) => _buildEmojiItem(emoji, context),
              ),
      ),
    );
  }

  Widget _buildEmojiItem(EmojiCandidate emoji, BuildContext context) {
    final isSelfVoted = _hasSelfVote(emoji);
    final designVariables = DesignVariables.of(context);

    return InkWell(
      onTap: () {
        MessagesListService.addOrRemoveReaction(
          isSelfVoted: isSelfVoted,
          messageId: message.message.id,
          emoji: emoji,
        );
        Get.back();
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: isSelfVoted
              ? designVariables.contextMenuItemBg.withFadedAlpha(0.4)
              : Colors.transparent,
          shape: BoxShape.circle,
        ),
        child: Center(
          child: switch (emoji.emojiDisplay) {
            ImageEmojiDisplay() => ImageEmojiWidget(
              emojiDisplay: emoji.emojiDisplay as ImageEmojiDisplay,
              size: 24,
              errorBuilder: (_, _, _) => SizedBox.shrink(),
            ),
            UnicodeEmojiDisplay() => UnicodeEmojiWidget(
              emojiDisplay: emoji.emojiDisplay as UnicodeEmojiDisplay,
              size: 24,
            ),
            TextEmojiDisplay() => SizedBox.shrink(),
          },
        ),
      ),
    );
  }

  Widget _buildExpandButton() {
    return InkWell(
      onTap: () {
        onExpand();
      },
      child: Container(
        width: 40,
        height: 40,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white10,
        ),
        child: const Icon(
          ZulipIcons.chevron_down,
          color: Colors.white,
          size: 20,
        ),
      ),
    );
  }
}

class EmojiSection {
  final EmojiCategoryType category;
  final List<EmojiCandidate> emojis;

  EmojiSection(this.category, this.emojis);
}

class EmojiPickerGrid extends StatefulWidget {
  final List<EmojiSection> sections;
  final Widget Function(EmojiCandidate) itemBuilder;

  const EmojiPickerGrid({
    super.key,
    required this.sections,
    required this.itemBuilder,
  });

  @override
  State<EmojiPickerGrid> createState() => _EmojiPickerGridState();
}

class _EmojiPickerGridState extends State<EmojiPickerGrid> {
  final ScrollController _scrollController = ScrollController();
  final Map<EmojiCategoryType, GlobalKey> _keys = {};
  EmojiCategoryType? _activeCategory;

  @override
  void initState() {
    super.initState();

    for (final section in widget.sections) {
      _keys[section.category] = GlobalKey();
    }

    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    for (final entry in _keys.entries) {
      final context = entry.value.currentContext;
      if (context == null) continue;

      final box = context.findRenderObject() as RenderBox;
      final position = box.localToGlobal(Offset.zero);

      if (position.dy <= 100) {
        if (_activeCategory != entry.key) {
          setState(() {
            _activeCategory = entry.key;
          });
        }
      }
    }
  }

  void _scrollToCategory(EmojiCategoryType category) {
    final key = _keys[category];
    final context = key?.currentContext;

    if (context != null) {
      Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
      );
    }
  }

  Widget _buildCategoryBar() {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.white54),
        ),
      ),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: widget.sections.map((section) {
          final isActive = section.category == _activeCategory;

          return GestureDetector(
            onTap: () => _scrollToCategory(section.category),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              alignment: Alignment.center,
              child: Text(
                _categoryLabel(section.category),
                style: TextStyle(
                  color: isActive ? Colors.blue : Colors.grey,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  String _categoryLabel(EmojiCategoryType type) {
    switch (type) {
      case EmojiCategoryType.popular:
        return '⭐';
      case EmojiCategoryType.smileys:
        return '😀';
      case EmojiCategoryType.people:
        return '👋';
      case EmojiCategoryType.animals:
        return '🐻';
      case EmojiCategoryType.food:
        return '🍔';
      case EmojiCategoryType.activities:
        return '⚽';
      case EmojiCategoryType.travel:
        return '🚗';
      case EmojiCategoryType.objects:
        return '💡';
      case EmojiCategoryType.symbols:
        return '❤️';
      case EmojiCategoryType.flags:
        return '🏳️';
      case EmojiCategoryType.realm:
        return '🏢';
      case EmojiCategoryType.zulipExtra:
        return '🟣';
    }
  }

  Widget _buildHeader(EmojiCategoryType category) {
    return Container(
      key: _keys[category],
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Text(
        category.name,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildCategoryBar(),
        Expanded(
          child: CustomScrollView(
            controller: _scrollController,
            slivers: [
              for (final section in widget.sections) ...[
                SliverToBoxAdapter(child: _buildHeader(section.category)),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  sliver: SliverGrid(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final emoji = section.emojis[index];
                      return widget.itemBuilder(emoji);
                    }, childCount: section.emojis.length),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 7,
                          mainAxisSpacing: 4,
                          crossAxisSpacing: 4,
                        ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
