import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../providers/parent_app_provider.dart';
import '../screens/auth/link_child_screen.dart';

class ChildSelectorSheet extends StatelessWidget {
  const ChildSelectorSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => const ChildSelectorSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ParentAppProvider>(context);
    final children = provider.children;
    final selectedChild = provider.selectedChild;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Switch Student Profile',
              style: AppTextStyles.headingMedium,
            ),
            const SizedBox(height: 6),
            Text(
              'Select a child to view their specific attendance, homework, fees and results.',
              style: AppTextStyles.bodyMedium,
            ),
            const SizedBox(height: 20),
            if (children.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Center(
                  child: Column(
                    children: [
                      const Icon(Icons.person_off_outlined, size: 48, color: AppColors.textMuted),
                      const SizedBox(height: 12),
                      Text('No children linked yet', style: AppTextStyles.headingSmall),
                      const SizedBox(height: 4),
                      Text(
                        'Use your school\'s Parent Access Code to link your child.',
                        style: AppTextStyles.caption,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: children.length,
                separatorBuilder: (context, index) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final child = children[index];
                  final isSelected = provider.isChildLinked && child.id == selectedChild.id;

                  return InkWell(
                    onTap: () {
                      provider.selectChild(child);
                      Navigator.pop(context);
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.infoBg : AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected ? AppColors.brandBlue : AppColors.border,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 26,
                            backgroundImage: NetworkImage(child.avatarUrl),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  child.name,
                                  style: AppTextStyles.headingSmall.copyWith(
                                    color: isSelected ? AppColors.brandBlue : AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${child.grade} (${child.className}) • Roll No. ${child.rollNo}',
                                  style: AppTextStyles.bodySmall,
                                ),
                              ],
                            ),
                          ),
                          if (isSelected)
                            const CircleAvatar(
                              radius: 12,
                              backgroundColor: AppColors.brandBlue,
                              child: Icon(Icons.check, size: 16, color: Colors.white),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const LinkChildScreen()),
                  );
                },
                icon: const Icon(Icons.add_rounded, color: AppColors.brandIndigo),
                label: Text('Link Another Child', style: AppTextStyles.button.copyWith(color: AppColors.brandIndigo)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.brandIndigo, width: 1.5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
