import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

class QuickActionItemData {
  final IconData icon;
  final String label;
  final Color iconColor;
  final Color bgColor;
  final VoidCallback onTap;
  final String? badgeText;
  final Color? badgeColor;

  const QuickActionItemData({
    required this.icon,
    required this.label,
    required this.iconColor,
    required this.bgColor,
    required this.onTap,
    this.badgeText,
    this.badgeColor,
  });
}

class QuickAccessGrid extends StatelessWidget {
  final List<QuickActionItemData> actions;

  const QuickAccessGrid({super.key, required this.actions});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        // Responsive column calculation
        int crossAxisCount;
        double childAspectRatio;

        if (width >= 800) {
          crossAxisCount = 8;
          childAspectRatio = 0.95;
        } else if (width >= 550) {
          crossAxisCount = 4;
          childAspectRatio = 1.05;
        } else if (width >= 370) {
          crossAxisCount = 4;
          childAspectRatio = 0.84;
        } else if (width >= 310) {
          crossAxisCount = 4;
          childAspectRatio = 0.78;
        } else {
          crossAxisCount = 2;
          childAspectRatio = 1.3;
        }

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: actions.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: childAspectRatio,
          ),
          itemBuilder: (context, index) {
            return _QuickAccessTile(data: actions[index]);
          },
        );
      },
    );
  }
}

class _QuickAccessTile extends StatefulWidget {
  final QuickActionItemData data;

  const _QuickAccessTile({required this.data});

  @override
  State<_QuickAccessTile> createState() => _QuickAccessTileState();
}

class _QuickAccessTileState extends State<_QuickAccessTile> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 130),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.94).animate(
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
    final item = widget.data;
    final disableAnimations = MediaQuery.of(context).disableAnimations;

    Widget content = Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.border,
          width: 1,
        ),
        boxShadow: isDark
            ? null
            : const [
                BoxShadow(
                  color: Color(0x060F172A),
                  blurRadius: 6,
                  offset: Offset(0, 2),
                ),
              ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon Container with soft pastel tint
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isDark ? item.iconColor.withOpacity(0.18) : item.bgColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Icon(
                    item.icon,
                    color: item.iconColor,
                    size: 21,
                  ),
                ),
              ),
              const SizedBox(height: 6),

              // Fully readable label (2 lines max, no harsh truncations)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2.0),
                child: Text(
                  item.label,
                  style: AppTextStyles.caption.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                    height: 1.15,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),

          // Optional Badge (e.g. pending homework count or fee due)
          if (item.badgeText != null)
            Positioned(
              top: -2,
              right: 2,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: item.badgeColor ?? AppColors.warning,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x25000000),
                      blurRadius: 3,
                      offset: Offset(0, 1),
                    ),
                  ],
                ),
                child: Text(
                  item.badgeText!,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 8.5,
                    fontWeight: FontWeight.bold,
                    height: 1,
                  ),
                ),
              ),
            ),
        ],
      ),
    );

    if (disableAnimations) {
      return InkWell(
        onTap: item.onTap,
        borderRadius: BorderRadius.circular(16),
        child: content,
      );
    }

    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        item.onTap();
      },
      onTapCancel: () => _controller.reverse(),
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) => Transform.scale(
          scale: _scaleAnimation.value,
          child: content,
        ),
      ),
    );
  }
}
