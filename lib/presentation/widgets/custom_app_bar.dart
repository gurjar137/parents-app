import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/greeting_helper.dart';
import '../../providers/parent_app_provider.dart';
import '../screens/notifications/notifications_screen.dart';
import '../screens/profile/parent_profile_screen.dart';
import 'child_selector_sheet.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  const CustomAppBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(78);

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ParentAppProvider>(context);
    final parent = provider.parent;
    final selectedChild = provider.selectedChild;
    final unreadCount = provider.unreadNotificationsCount;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final greeting = GreetingHelper.getGreeting();
    final fatherName = provider.currentFatherName;

    final displayName = fatherName.isNotEmpty
        ? fatherName
        : (parent.name.isNotEmpty && parent.name != 'Parent User' && parent.name != 'Parent'
            ? parent.name
            : 'Parent');

    return SafeArea(
      child: Container(
        height: preferredSize.height,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.surface,
          border: Border(
            bottom: BorderSide(
              color: isDark ? AppColors.darkBorder : AppColors.border.withOpacity(0.6),
              width: 1,
            ),
          ),
          boxShadow: isDark
              ? null
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Row(
          children: [
            // 1. Authenticated Parent Avatar with Gradient Accent Ring
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ParentProfileScreen()),
                );
              },
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [AppColors.brandIndigo, AppColors.brandBlue],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: CircleAvatar(
                  radius: 20,
                  backgroundColor: isDark ? AppColors.darkSubSurface : Colors.white,
                  backgroundImage: (parent.avatarUrl.isNotEmpty && parent.avatarUrl.startsWith('http'))
                      ? NetworkImage(parent.avatarUrl)
                      : null,
                  child: (parent.avatarUrl.isEmpty || !parent.avatarUrl.startsWith('http'))
                      ? Text(
                          displayName.isNotEmpty ? displayName[0].toUpperCase() : 'P',
                          style: const TextStyle(
                            color: AppColors.brandIndigo,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        )
                      : null,
                ),
              ),
            ),

            const SizedBox(width: 12),

            // 2. Greeting, Parent Name & Verified Child Selector Pill
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Greeting & Real Display Name
                  Text(
                    '$greeting, $displayName',
                    style: AppTextStyles.headingSmall.copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),

                  // Child Selector & School Identity
                  Row(
                    children: [
                      Flexible(
                        child: InkWell(
                          onTap: () => ChildSelectorSheet.show(context),
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                            decoration: BoxDecoration(
                              color: isDark ? AppColors.darkInfoBg : AppColors.infoBg,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isDark ? AppColors.brandBlue.withOpacity(0.4) : AppColors.brandBlue.withOpacity(0.25),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Flexible(
                                  child: Text(
                                    provider.isChildLinked
                                        ? '${selectedChild.name} (${selectedChild.className})'
                                        : 'Link Student',
                                    style: AppTextStyles.caption.copyWith(
                                      color: AppColors.brandBlue,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 11,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 3),
                                const Icon(
                                  Icons.keyboard_arrow_down_rounded,
                                  size: 14,
                                  color: AppColors.brandBlue,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      if (provider.isChildLinked && provider.branding.schoolName.isNotEmpty) ...[
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            '• ${provider.branding.schoolName}',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.textSecondary,
                              fontSize: 10.5,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),

            // 3. Notification Bell with Real Unread Count
            Stack(
              clipBehavior: Clip.none,
              children: [
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const NotificationsScreen()),
                      );
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkSubSurface : AppColors.subSurface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDark ? AppColors.darkBorder : AppColors.border,
                          width: 1,
                        ),
                      ),
                      child: Icon(
                        Icons.notifications_outlined,
                        color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                        size: 20,
                      ),
                    ),
                  ),
                ),
                if (unreadCount > 0)
                  Positioned(
                    right: -2,
                    top: -2,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.danger,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isDark ? AppColors.darkSurface : Colors.white,
                          width: 1.5,
                        ),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x40EF4444),
                            blurRadius: 4,
                            offset: Offset(0, 1),
                          ),
                        ],
                      ),
                      constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                      child: Text(
                        unreadCount > 99 ? '99+' : '$unreadCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          height: 1,
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
