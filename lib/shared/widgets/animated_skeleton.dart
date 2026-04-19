import 'package:flutter/material.dart';

class AnimatedSkeleton extends StatefulWidget {
  final double? width;
  final double height;
  final double borderRadius;
  final EdgeInsetsGeometry? margin;
  final bool buildUpOnly;

  const AnimatedSkeleton({
    super.key,
    this.width,
    required this.height,
    this.borderRadius = 12.0,
    this.margin,
    this.buildUpOnly = false,
  });

  @override
  State<AnimatedSkeleton> createState() => _AnimatedSkeletonState();
}

class _AnimatedSkeletonState extends State<AnimatedSkeleton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Color?> _colorAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    if (widget.buildUpOnly) {
      _controller.forward();
    } else {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Light, Dark, Darker animation
    final lightColor = isDark
        ? Colors.white.withOpacity(0.04)
        : const Color(0xFF1B5E20).withOpacity(0.04);
    final darkColor = isDark
        ? Colors.white.withOpacity(0.08)
        : const Color(0xFF1B5E20).withOpacity(0.08);
    final darkerColor = isDark
        ? Colors.white.withOpacity(0.12)
        : const Color(0xFF1B5E20).withOpacity(0.12);

    _colorAnimation = TweenSequence<Color?>([
      TweenSequenceItem(
        weight: 1.0,
        tween: ColorTween(begin: lightColor, end: darkColor),
      ),
      TweenSequenceItem(
        weight: 1.0,
        tween: ColorTween(begin: darkColor, end: darkerColor),
      ),
    ]).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _colorAnimation,
      builder: (context, child) {
        return Container(
          margin: widget.margin,
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: _colorAnimation.value,
            borderRadius: BorderRadius.circular(widget.borderRadius),
          ),
        );
      },
    );
  }
}
