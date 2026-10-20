import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class AnimatedCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final Color? backgroundColor;
  final Gradient? gradient;
  final Border? border;
  final BorderRadiusGeometry? borderRadius;
  final List<BoxShadow>? boxShadow;

  const AnimatedCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(16),
    this.backgroundColor,
    this.gradient,
    this.border,
    this.borderRadius,
    this.boxShadow,
  });

  @override
  State<AnimatedCard> createState() => _AnimatedCardState();
}

class _AnimatedCardState extends State<AnimatedCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 140),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.985).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final defaultBg = isDark ? AppColors.darkSurface : AppColors.surface;
    final defaultBorder = Border.all(
      color: isDark ? AppColors.darkBorder : AppColors.border,
      width: 1,
    );
    final effectiveRadius = widget.borderRadius ?? BorderRadius.circular(18);
    final disableAnimations = MediaQuery.of(context).disableAnimations;

    Widget cardContent = Container(
      padding: widget.padding,
      decoration: BoxDecoration(
        color: widget.gradient == null ? (widget.backgroundColor ?? defaultBg) : null,
        gradient: widget.gradient,
        borderRadius: effectiveRadius,
        border: widget.border ?? defaultBorder,
        boxShadow: widget.boxShadow ?? AppColors.cardShadow,
      ),
      child: widget.child,
    );

    if (widget.onTap == null) {
      return cardContent;
    }

    if (disableAnimations) {
      return InkWell(
        onTap: widget.onTap,
        borderRadius: effectiveRadius is BorderRadius ? effectiveRadius : BorderRadius.circular(18),
        child: cardContent,
      );
    }

    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap!();
      },
      onTapCancel: () => _controller.reverse(),
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) => Transform.scale(
          scale: _scaleAnimation.value,
          child: cardContent,
        ),
      ),
    );
  }
}
