import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../providers/parent_app_provider.dart';
import '../../widgets/animated_card.dart';
import '../transport/transport_screen.dart';
import '../calendar/school_calendar_screen.dart';
import '../ai_assistant/ai_assistant_screen.dart';
import '../ptm/ptm_screen.dart';
import '../documents/documents_screen.dart';
import '../class_info/class_info_screen.dart';
import '../profile/parent_profile_screen.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ParentAppProvider>(context);
    final parent = provider.parent;
    final child = provider.selectedChild;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text('More Services', style: AppTextStyles.headingSmall),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Parent Mini Profile Card
            AnimatedCard(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ParentProfileScreen()),
                );
              },
              backgroundColor: AppColors.primary,
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundImage: NetworkImage(parent.avatarUrl),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(parent.name, style: AppTextStyles.headingSmall.copyWith(color: Colors.white, fontSize: 16)),
                        Text('Active Child: ${child.name} (${child.className})', style: AppTextStyles.caption.copyWith(color: Colors.white70)),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded, color: Colors.white70),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Student Services Grid
            Text('Student & School Services', style: AppTextStyles.headingSmall),
            const SizedBox(height: 12),

            _buildServiceTile(
              icon: Icons.directions_bus_rounded,
              title: 'School Bus & Transport',
              subtitle: 'Live route tracking, driver contact, bus stops',
              color: AppColors.brandBlue,
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const TransportScreen()));
              },
            ),
            _buildServiceTile(
              icon: Icons.calendar_month_rounded,
              title: 'Academic Calendar',
              subtitle: 'Holidays, exams, PTMs & annual school events',
              color: AppColors.holiday,
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const SchoolCalendarScreen()));
              },
            ),
            _buildServiceTile(
              icon: Icons.auto_awesome_rounded,
              title: 'Parent AI Assistant',
              subtitle: 'Instant answers for attendance, homework & fees',
              color: AppColors.brandIndigo,
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const AiAssistantScreen()));
              },
            ),
            _buildServiceTile(
              icon: Icons.groups_rounded,
              title: 'Parent-Teacher Meeting (PTM)',
              subtitle: 'Slot reservations, teacher venue & schedules',
              color: AppColors.success,
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const PtmScreen()));
              },
            ),
            _buildServiceTile(
              icon: Icons.folder_open_rounded,
              title: 'Documents Vault',
              subtitle: 'Official report cards, fee receipts & certificates',
              color: AppColors.warning,
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const DocumentsScreen()));
              },
            ),
            _buildServiceTile(
              icon: Icons.school_rounded,
              title: 'Class & Teacher Info',
              subtitle: 'Class ${child.className} curriculum and faculty list',
              color: AppColors.danger,
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const ClassInfoScreen()));
              },
            ),

            const SizedBox(height: 24),

            // App Preferences & Theme
            Text('Preferences & Settings', style: AppTextStyles.headingSmall),
            const SizedBox(height: 12),

            AnimatedCard(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: const BoxDecoration(color: AppColors.subSurface, shape: BoxShape.circle),
                    child: Icon(
                      isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                      color: AppColors.brandIndigo,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Theme Mode', style: AppTextStyles.headingSmall.copyWith(fontSize: 14)),
                        Text(isDark ? 'Dark Theme' : 'Light Theme', style: AppTextStyles.caption),
                      ],
                    ),
                  ),
                  Switch(
                    value: isDark,
                    activeColor: AppColors.brandIndigo,
                    onChanged: (_) => provider.toggleTheme(),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            _buildServiceTile(
              icon: Icons.person_outline_rounded,
              title: 'Parent Account & Security',
              subtitle: 'Biometric lock, verified mobile & linked children',
              color: AppColors.brandIndigo,
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const ParentProfileScreen()));
              },
            ),

            const SizedBox(height: 8),

            _buildServiceTile(
              icon: Icons.logout_rounded,
              title: 'Log Out',
              subtitle: 'End current parent session safely',
              color: AppColors.danger,
              onTap: () {
                _showLogoutDialog(context, provider);
              },
            ),

            const SizedBox(height: 20),

            // School Affiliation Info Footer
            Center(
              child: Column(
                children: [
                  Text(AppConstants.schoolName, style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.bold)),
                  Text('${provider.branding.affiliation} • Version 2.0 (Premium Build)', style: AppTextStyles.caption),
                ],
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: AnimatedCard(
        onTap: onTap,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTextStyles.headingSmall.copyWith(fontSize: 14)),
                  Text(subtitle, style: AppTextStyles.caption),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, ParentAppProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.logout_rounded, color: AppColors.danger),
            const SizedBox(width: 10),
            Text('Log Out', style: AppTextStyles.headingSmall.copyWith(fontSize: 16)),
          ],
        ),
        content: const Text(
          'Are you sure you want to log out? You will need your Parent ID to sign back in.',
        ),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              provider.logout();
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            child: const Text('Log Out'),
          ),
        ],
      ),
    );
  }
}
