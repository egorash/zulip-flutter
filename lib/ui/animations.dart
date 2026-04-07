import 'package:flutter/material.dart';

const Duration kShortPressDuration = Duration(milliseconds: 100);
const Duration kMediumPressDuration = Duration(milliseconds: 150);
const Duration kLongPressDuration = Duration(milliseconds: 200);

const Curve kDefaultPressCurve = Curves.easeOut;
const Curve kDefaultTransitionCurve = Curves.easeInOut;

class ZulipAnimations {
  ZulipAnimations._();

  static const Duration bottomSheetDuration = Duration(milliseconds: 250);
  static const Duration fadeInDuration = Duration(milliseconds: 200);
  static const Duration scalePressDuration = Duration(milliseconds: 100);
  static const Duration pageTransitionDuration = Duration(milliseconds: 300);

  static const Curve pageTransitionCurve = Curves.easeInOut;
  static const Curve bottomSheetCurve = Curves.easeOutCubic;
  static const Curve fadeInCurve = Curves.easeOut;
}

class AnimatedPressScale extends StatelessWidget {
  const AnimatedPressScale({
    super.key,
    required this.child,
    this.scaleEnd = 0.96,
    this.duration = kShortPressDuration,
    this.enabled = true,
  });

  final Widget child;
  final double scaleEnd;
  final Duration duration;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    if (!enabled) {
      return child;
    }

    return GestureDetector(
      onTapDown: (_) {},
      onTapUp: (_) {},
      onTapCancel: () {},
      child: child,
    );
  }
}

class AnimatedPressOpacity extends StatelessWidget {
  const AnimatedPressOpacity({
    super.key,
    required this.child,
    this.opacityEnd = 0.7,
    this.duration = kShortPressDuration,
    this.enabled = true,
  });

  final Widget child;
  final double opacityEnd;
  final Duration duration;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    if (!enabled) {
      return child;
    }

    return _AnimatedPressOpacityWidget(
      opacityEnd: opacityEnd,
      duration: duration,
      child: child,
    );
  }
}

class _AnimatedPressOpacityWidget extends StatefulWidget {
  const _AnimatedPressOpacityWidget({
    required this.opacityEnd,
    required this.duration,
    required this.child,
  });

  final double opacityEnd;
  final Duration duration;
  final Widget child;

  @override
  State<_AnimatedPressOpacityWidget> createState() =>
      _AnimatedPressOpacityWidgetState();
}

class _AnimatedPressOpacityWidgetState
    extends State<_AnimatedPressOpacityWidget> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedOpacity(
        opacity: _isPressed ? widget.opacityEnd : 1.0,
        duration: widget.duration,
        curve: kDefaultPressCurve,
        child: widget.child,
      ),
    );
  }
}

class AnimatedFadeIn extends StatelessWidget {
  const AnimatedFadeIn({
    super.key,
    required this.child,
    this.duration = ZulipAnimations.fadeInDuration,
    this.delay = Duration.zero,
    this.begin = 0.0,
    this.curve = Curves.easeOut,
  });

  final Widget child;
  final Duration duration;
  final Duration delay;
  final double begin;
  final Curve curve;

  @override
  Widget build(BuildContext context) {
    return _SimpleFadeInWidget(
      duration: duration,
      delay: delay,
      begin: begin,
      curve: curve,
      child: child,
    );
  }
}

class _SimpleFadeInWidget extends StatefulWidget {
  const _SimpleFadeInWidget({
    required this.duration,
    required this.delay,
    required this.begin,
    required this.curve,
    required this.child,
  });

  final Duration duration;
  final Duration delay;
  final double begin;
  final Curve curve;
  final Widget child;

  @override
  State<_SimpleFadeInWidget> createState() => _SimpleFadeInWidgetState();
}

class _SimpleFadeInWidgetState extends State<_SimpleFadeInWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: widget.duration, vsync: this);
    _animation = Tween<double>(
      begin: widget.begin,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: widget.curve));

    if (widget.delay == Duration.zero) {
      _started = true;
      _controller.forward();
    } else {
      Future.delayed(widget.delay, () {
        if (mounted) {
          _started = true;
          _controller.forward();
        }
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_started) {
      return Opacity(opacity: 0, child: widget.child);
    }
    return FadeTransition(opacity: _animation, child: widget.child);
  }
}

class AnimatedSlideIn extends StatelessWidget {
  const AnimatedSlideIn({
    super.key,
    required this.child,
    this.duration = ZulipAnimations.fadeInDuration,
    this.delay = Duration.zero,
    this.beginOffset = const Offset(0, 0.1),
    this.curve = Curves.easeOut,
  });

  final Widget child;
  final Duration duration;
  final Duration delay;
  final Offset beginOffset;
  final Curve curve;

  @override
  Widget build(BuildContext context) {
    return _SimpleSlideInWidget(
      duration: duration,
      delay: delay,
      beginOffset: beginOffset,
      curve: curve,
      child: child,
    );
  }
}

class _SimpleSlideInWidget extends StatefulWidget {
  const _SimpleSlideInWidget({
    required this.duration,
    required this.delay,
    required this.beginOffset,
    required this.curve,
    required this.child,
  });

  final Duration duration;
  final Duration delay;
  final Offset beginOffset;
  final Curve curve;
  final Widget child;

  @override
  State<_SimpleSlideInWidget> createState() => _SimpleSlideInWidgetState();
}

class _SimpleSlideInWidgetState extends State<_SimpleSlideInWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: widget.duration, vsync: this);
    _slideAnimation = Tween<Offset>(
      begin: widget.beginOffset,
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: widget.curve));
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: widget.curve));

    if (widget.delay == Duration.zero) {
      _started = true;
      _controller.forward();
    } else {
      Future.delayed(widget.delay, () {
        if (mounted) {
          _started = true;
          _controller.forward();
        }
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_started) {
      return Opacity(opacity: 0, child: widget.child);
    }
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(position: _slideAnimation, child: widget.child),
    );
  }
}

class AnimatedListItem extends StatelessWidget {
  const AnimatedListItem({
    super.key,
    required this.child,
    this.index = 0,
    this.enabled = true,
  });

  final Widget child;
  final int index;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    if (!enabled) {
      return child;
    }

    return AnimatedSlideIn(
      beginOffset: const Offset(0, 0.05),
      delay: Duration(milliseconds: index * 30),
      child: child,
    );
  }
}

class AnimatedPressIndicator extends StatelessWidget {
  const AnimatedPressIndicator({
    super.key,
    required this.child,
    this.type = AnimatedPressIndicatorType.scale,
    this.scaleEnd = 0.95,
    this.opacityEnd = 0.7,
    this.duration = kShortPressDuration,
  });

  final Widget child;
  final AnimatedPressIndicatorType type;
  final double scaleEnd;
  final double opacityEnd;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    return _AnimatedPressIndicatorWidget(
      type: type,
      scaleEnd: scaleEnd,
      opacityEnd: opacityEnd,
      duration: duration,
      child: child,
    );
  }
}

class _AnimatedPressIndicatorWidget extends StatefulWidget {
  const _AnimatedPressIndicatorWidget({
    required this.type,
    required this.scaleEnd,
    required this.opacityEnd,
    required this.duration,
    required this.child,
  });

  final AnimatedPressIndicatorType type;
  final double scaleEnd;
  final double opacityEnd;
  final Duration duration;
  final Widget child;

  @override
  State<_AnimatedPressIndicatorWidget> createState() =>
      _AnimatedPressIndicatorWidgetState();
}

class _AnimatedPressIndicatorWidgetState
    extends State<_AnimatedPressIndicatorWidget> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? widget.scaleEnd : 1.0,
        duration: widget.duration,
        curve: kDefaultPressCurve,
        child: AnimatedOpacity(
          opacity: _isPressed ? widget.opacityEnd : 1.0,
          duration: widget.duration,
          curve: kDefaultPressCurve,
          child: widget.child,
        ),
      ),
    );
  }
}

enum AnimatedPressIndicatorType { scale, opacity, both }

class StaggeredAnimationList extends StatelessWidget {
  const StaggeredAnimationList({
    super.key,
    required this.children,
    this.itemDelay = const Duration(milliseconds: 50),
    this.animationDuration = const Duration(milliseconds: 200),
    this.curve = Curves.easeOut,
  });

  final List<Widget> children;
  final Duration itemDelay;
  final Duration animationDuration;
  final Curve curve;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (int i = 0; i < children.length; i++)
          AnimatedSlideIn(
            duration: animationDuration,
            delay: itemDelay * i,
            beginOffset: const Offset(0, 0.1),
            curve: curve,
            child: children[i],
          ),
      ],
    );
  }
}

class PulseAnimation extends StatefulWidget {
  const PulseAnimation({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 1000),
    this.scaleRange = 0.05,
  });

  final Widget child;
  final Duration duration;
  final double scaleRange;

  @override
  State<PulseAnimation> createState() => _PulseAnimationState();
}

class _PulseAnimationState extends State<PulseAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: widget.duration, vsync: this)
      ..repeat(reverse: true);
    _animation = Tween<double>(
      begin: 1.0 - widget.scaleRange,
      end: 1.0 + widget.scaleRange,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(scale: _animation, child: widget.child);
  }
}

Route<T> zulipPageRoute<T>({required Widget page, RouteSettings? settings}) {
  return PageRouteBuilder<T>(
    settings: settings,
    pageBuilder: (context, animation, secondaryAnimation) => page,
    transitionDuration: ZulipAnimations.pageTransitionDuration,
    reverseTransitionDuration: ZulipAnimations.pageTransitionDuration,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: animation,
        child: SlideTransition(
          position:
              Tween<Offset>(
                begin: const Offset(0.02, 0),
                end: Offset.zero,
              ).animate(
                CurvedAnimation(
                  parent: animation,
                  curve: ZulipAnimations.pageTransitionCurve,
                ),
              ),
          child: child,
        ),
      );
    },
  );
}

class ChatBackground extends StatelessWidget {
  const ChatBackground({super.key, required this.child, this.opacity = 0.04});

  final Widget child;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final iconColor = isDark ? Colors.white : Colors.black;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  const Color(0xFF1A1A2E),
                  const Color(0xFF16213E),
                  const Color(0xFF0F3460),
                ]
              : [
                  const Color(0xFFE8E8FF),
                  const Color(0xFFF0F4FF),
                  const Color(0xFFE0E8FF),
                ],
        ),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _IconPatternPainter(
                iconColor: iconColor.withValues(alpha: opacity),
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }
}

class _IconPatternPainter extends CustomPainter {
  _IconPatternPainter({required this.iconColor});

  final Color iconColor;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = iconColor
      ..style = PaintingStyle.fill;

    const spacing = 60.0;
    const seed = 1234567;

    for (double y = 0; y < size.height + spacing; y += spacing) {
      for (double x = 0; x < size.width + spacing; x += spacing) {
        final iconType = (seed * (x.toInt()) + y.toInt()) % 5;
        final offsetX = ((seed * (y.toInt() + 1)) % 40) - 20.0;
        final offsetY = ((seed * (x.toInt() + 1)) % 40) - 20.0;
        final rotation =
            ((seed * (x.toInt()) * y.toInt()) % 360) * 3.14159 / 180;
        final scale = 0.6 + ((seed * x.toInt() * y.toInt()) % 50) / 100;

        final center = Offset(x + offsetX, y + offsetY);

        canvas.save();
        canvas.translate(center.dx, center.dy);
        canvas.rotate(rotation);
        canvas.scale(scale);

        switch (iconType) {
          case 0:
            _drawChatBubble(canvas, paint);
          case 1:
            _drawEmail(canvas, paint);
          case 2:
            _drawUser(canvas, paint);
          case 3:
            _drawMessage(canvas, paint);
          case 4:
            _drawCircle(canvas, paint);
        }

        canvas.restore();
      }
    }
  }

  void _drawChatBubble(Canvas canvas, Paint paint) {
    const size = 24.0;
    final rect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset.zero, width: size, height: size * 0.8),
      Radius.circular(size * 0.2),
    );
    canvas.drawRRect(rect, paint);

    final tailPath = Path();
    tailPath.moveTo(-size * 0.15, size * 0.3);
    tailPath.lineTo(-size * 0.3, size * 0.45);
    tailPath.lineTo(-size * 0.05, size * 0.45);
    tailPath.close();
    canvas.drawPath(tailPath, paint);
  }

  void _drawEmail(Canvas canvas, Paint paint) {
    const size = 20.0;
    final rect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset.zero, width: size, height: size * 0.65),
      const Radius.circular(3),
    );
    canvas.drawRRect(rect, paint);

    final path = Path();
    path.moveTo(-size * 0.4, -size * 0.15);
    path.lineTo(0, size * 0.1);
    path.lineTo(size * 0.4, -size * 0.15);
    canvas.drawPath(
      path,
      paint
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
    paint.style = PaintingStyle.fill;
  }

  void _drawUser(Canvas canvas, Paint paint) {
    const size = 18.0;
    canvas.drawCircle(Offset.zero, size * 0.25, paint);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(0, size * 0.35),
        width: size * 0.6,
        height: size * 0.4,
      ),
      paint,
    );
  }

  void _drawMessage(Canvas canvas, Paint paint) {
    const size = 22.0;
    final rect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset.zero,
        width: size * 0.7,
        height: size * 0.5,
      ),
      Radius.circular(size * 0.1),
    );
    canvas.drawRRect(rect, paint);
  }

  void _drawCircle(Canvas canvas, Paint paint) {
    const size = 16.0;
    canvas.drawCircle(Offset.zero, size * 0.5, paint);
  }

  @override
  bool shouldRepaint(covariant _IconPatternPainter oldDelegate) {
    return oldDelegate.iconColor != iconColor;
  }
}
