import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/greeting_helper.dart';
import '../../providers/parent_app_provider.dart';
import '../screens/notifications/notifications_screen.dart';
import 'child_selector_sheet.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  const CustomAppBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(70);

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ParentAppProvider>(context);
    final parent = provider.parent;
    final selectedChild = provider.selectedChild;
    final unreadCount = provider.unreadNotificationsCount;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final greeting = GreetingHelper.getGreeting();
    final fatherName = provider.currentFatherName;

    return SafeArea(
      child: Container(
        color: isDark ? AppColors.darkSurface : AppColors.surface,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: AppColors.brandIndigo,
              backgroundImage: NetworkImage(parent.avatarUrl),
              child: Text(
                fatherName.isNotEmpty ? fatherName[0] : 'P',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    fatherName.isNotEmpty ? '$greeting, $fatherName 👋' : '$greeting 👋',
                    style: AppTextStyles.headingSmall.copyWith(fontSize: 15),
                  ),
                  const SizedBox(height: 2),
                  InkWell(
                    onTap: () => ChildSelectorSheet.show(context),
                    borderRadius: BorderRadius.circular(12),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.darkInfoBg : AppColors.infoBg,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.brandBlue.withOpacity(0.3)),
                          ),
                          child: Row(
                            children: [
                              Text(
                                provider.isChildLinked ? '${selectedChild.name} (${selectedChild.className})' : 'No child linked',
                                style: AppTextStyles.caption.copyWith(
                                  color: AppColors.brandBlue,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(
                                Icons.keyboard_arrow_down_rounded,
                                size: 14,
                                color: AppColors.brandBlue,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Stack(
              children: [
                IconButton(
                  icon: Icon(
                    Icons.notifications_outlined,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                    size: 24,
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const NotificationsScreen()),
                    );
                  },
                ),
                if (unreadCount > 0)
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: AppColors.danger,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                      child: Text(
                        '$unreadCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
