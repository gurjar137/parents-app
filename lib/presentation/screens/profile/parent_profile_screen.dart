import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/services/auth_service.dart';
import '../../../providers/parent_app_provider.dart';
import '../../widgets/animated_card.dart';
import '../notifications/notifications_screen.dart';
import '../auth/link_child_screen.dart';
import '../auth/parent_login_screen.dart';
import 'child_profile_screen.dart';

class ParentProfileScreen extends StatefulWidget {
  const ParentProfileScreen({super.key});

  @override
  State<ParentProfileScreen> createState() => _ParentProfileScreenState();
}

class _ParentProfileScreenState extends State<ParentProfileScreen> {
  bool _biometricLock = true;

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ParentAppProvider>(context);
    final parent = provider.parent;
    final children = provider.children;

    return Scaffold(
      appBar: AppBar(
        title: Text('My Profile & Settings', style: AppTextStyles.headingSmall),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Parent Dossier Card
            AnimatedCard(
              backgroundColor: AppColors.primary,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 32,
                      backgroundColor: AppColors.brandIndigo,
                      backgroundImage: parent.avatarUrl.startsWith('http') ? NetworkImage(parent.avatarUrl) : null,
                      child: parent.avatarUrl.startsWith('http')
                          ? null
                          : Text(parent.name.isNotEmpty ? parent.name[0].toUpperCase() : '?',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(parent.name, style: AppTextStyles.headingSmall.copyWith(color: Colors.white, fontSize: 18)),
                          const SizedBox(height: 2),
                          Text(parent.relationship, style: AppTextStyles.caption.copyWith(color: Colors.white70)),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.email_outlined, color: Colors.white70, size: 14),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(parent.email, style: AppTextStyles.bodySmall.copyWith(color: Colors.white70), overflow: TextOverflow.ellipsis),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              const Icon(Icons.phone_android_rounded, color: Colors.white70, size: 14),
                              const SizedBox(width: 4),
                              Text(parent.phone.isNotEmpty ? parent.phone : 'Phone not provided', style: AppTextStyles.bodySmall.copyWith(color: Colors.white70)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit_rounded, color: Colors.white),
                      onPressed: () => _showEditProfileModal(context, provider),
                      tooltip: 'Edit Profile',
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Linked Children Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('My Children (${children.length})', style: AppTextStyles.headingSmall),
                TextButton.icon(
                  icon: const Icon(Icons.add_circle_outline_rounded, size: 18),
                  label: const Text('+ Link Another Child'),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const LinkChildScreen()),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            Column(
              children: children.map((child) {
                final isSelected = provider.isChildLinked && child.id == provider.selectedChild.id;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: AnimatedCard(
                    onTap: () {
                      provider.selectChild(child);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => ChildProfileScreen(student: child)),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(14.0),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundColor: AppColors.brandIndigo,
                            backgroundImage: child.avatarUrl.startsWith('http') ? NetworkImage(child.avatarUrl) : null,
                            child: child.avatarUrl.startsWith('http')
                                ? null
                                : Text(child.name.isNotEmpty ? child.name[0].toUpperCase() : '?',
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(child.name, style: AppTextStyles.headingSmall.copyWith(fontSize: 15)),
                                    if (isSelected) ...[
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: AppColors.infoBg,
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text('Active', style: AppTextStyles.caption.copyWith(color: AppColors.brandBlue, fontSize: 10)),
                                      ),
                                    ],
                                  ],
                                ),
                                Text(['Class ${child.className}', if (child.rollNo > 0) 'Roll No. ${child.rollNo}', if (child.admissionNo.isNotEmpty) 'Adm. ${child.admissionNo}'].join(' • '), style: AppTextStyles.bodySmall),
                              ],
                            ),
                          ),
                          const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textMuted),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 24),

            // Account & Security Settings
            Text('Account & Security Settings', style: AppTextStyles.headingSmall),
            const SizedBox(height: 12),

            _buildOptionTile(
              icon: Icons.person_outline_rounded,
              title: 'Edit Profile Particulars',
              subtitle: 'Update full name & phone number',
              onTap: () => _showEditProfileModal(context, provider),
            ),
            _buildOptionTile(
              icon: Icons.lock_outline_rounded,
              title: 'Change Password',
              subtitle: 'Update account password via Supabase Auth',
              onTap: () => _showChangePasswordModal(context, provider),
            ),
            _buildSwitchTile(
              icon: Icons.fingerprint_rounded,
              title: 'Biometric Lock (Fingerprint/FaceID)',
              subtitle: 'Require biometric scan when opening app',
              value: _biometricLock,
              onChanged: (val) {
                setState(() => _biometricLock = val);
              },
            ),
            _buildOptionTile(
              icon: Icons.notifications_none_rounded,
              title: 'Notification Settings',
              subtitle: 'Configure push alerts & category rules',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const NotificationsScreen()),
                );
              },
            ),
            _buildOptionTile(
              icon: Icons.school_outlined,
              title: 'School Information',
              subtitle: provider.branding.schoolName,
              onTap: () => _showSchoolInfoDialog(context, provider),
            ),
            _buildOptionTile(
              icon: Icons.info_outline_rounded,
              title: 'About Parent Portal App',
              subtitle: 'Version 1.2.0 • Build 2026.09.01',
              onTap: () => _showAboutAppDialog(context),
            ),
            _buildOptionTile(
              icon: Icons.privacy_tip_outlined,
              title: 'Privacy Policy & Terms of Service',
              subtitle: 'Encrypted cloud data & authorization policy',
              onTap: () => _showPrivacyPolicyDialog(context),
            ),
            _buildOptionTile(
              icon: Icons.logout_rounded,
              title: 'Logout Account',
              subtitle: 'Sign out safely from this device',
              onTap: () => _showLogoutDialog(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: AnimatedCard(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: const BoxDecoration(
                color: AppColors.subSurface,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppColors.brandIndigo, size: 20),
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
            Switch(
              value: value,
              activeColor: AppColors.brandIndigo,
              onChanged: onChanged,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionTile({
    required IconData icon,
    required String title,
    required String subtitle,
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
              decoration: const BoxDecoration(
                color: AppColors.subSurface,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppColors.brandIndigo, size: 20),
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

  void _showEditProfileModal(BuildContext context, ParentAppProvider provider) {
    final nameCtrl = TextEditingController(text: provider.parent.name);
    final phoneCtrl = TextEditingController(text: provider.parent.phone);
    final relCtrl = TextEditingController(text: provider.parent.relationship);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Edit Profile Particulars', style: AppTextStyles.headingMedium),
              const SizedBox(height: 16),
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Full Name'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phoneCtrl,
                decoration: const InputDecoration(labelText: 'Phone Number'),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: relCtrl,
                decoration: const InputDecoration(labelText: 'Relationship (Father/Mother/Guardian)'),
              ),
              const SizedBox(height: 12),
              Text('Email: ${provider.parent.email} (Read-only)', style: AppTextStyles.caption.copyWith(color: AppColors.textMuted)),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.brandIndigo),
                  onPressed: () async {
                    final ok = await provider.updateProfile(
                      name: nameCtrl.text,
                      phone: phoneCtrl.text,
                      relationship: relCtrl.text,
                    );
                    if (context.mounted) {
                      if (ok) Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(ok
                              ? 'Profile updated.'
                              : 'The profile could not be saved. Check the name and phone number and try again.'),
                          backgroundColor: ok ? AppColors.success : AppColors.danger,
                        ),
                      );
                    }
                  },
                  child: const Text('Save Changes'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showChangePasswordModal(BuildContext context, ParentAppProvider provider) {
    final newPassCtrl = TextEditingController();
    final confirmPassCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Change Account Password', style: AppTextStyles.headingMedium),
              const SizedBox(height: 6),
              Text('Update your password securely via Supabase Auth:', style: AppTextStyles.bodySmall),
              const SizedBox(height: 16),
              TextField(
                controller: newPassCtrl,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'New Password'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: confirmPassCtrl,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Confirm New Password'),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.brandIndigo),
                  onPressed: () async {
                    final res = await provider.updatePassword(
                      newPassword: newPassCtrl.text,
                      confirmPassword: confirmPassCtrl.text,
                    );
                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(res.userMessage ?? res.errorMessage ?? 'Password updated successfully.'),
                          backgroundColor: res.status == AuthStatus.success ? AppColors.success : AppColors.danger,
                        ),
                      );
                    }
                  },
                  child: const Text('Update Password'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showSchoolInfoDialog(BuildContext context, ParentAppProvider provider) {
    final branding = provider.branding;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(branding.schoolName, style: AppTextStyles.headingSmall),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Address: ${branding.address.isNotEmpty ? branding.address : "Not provided"}', style: AppTextStyles.bodyMedium),
            const SizedBox(height: 8),
            Text('Phone: ${branding.phone.isNotEmpty ? branding.phone : "Not provided"}', style: AppTextStyles.bodyMedium),
            const SizedBox(height: 8),
            Text('Email: ${branding.email.isNotEmpty ? branding.email : "Not provided"}', style: AppTextStyles.bodyMedium),
            const SizedBox(height: 8),
            Text('Affiliation Code: ${branding.affiliation.isNotEmpty ? branding.affiliation : "Not provided"}', style: AppTextStyles.bodyMedium),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showAboutAppDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('About Parent Portal', style: AppTextStyles.headingSmall),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('School Management Parent Application', style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text('Version: 1.2.0 (Build 2026.09.01)', style: AppTextStyles.bodySmall),
            const SizedBox(height: 12),
            Text('Designed for real-time parent-school communication, tracking attendance, homework, timetables, exam results, fees, notices, and mobile push notifications.', style: AppTextStyles.bodySmall),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showPrivacyPolicyDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Privacy Policy & Terms', style: AppTextStyles.headingSmall),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Data Privacy & Security Standard', style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text('All parent-student academic records, fee transactions, and push notifications are protected by Row Level Security (RLS) policies on Supabase cloud backend.', style: AppTextStyles.bodySmall),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Logout Account', style: AppTextStyles.headingSmall),
        content: Text('Are you sure you want to sign out from your parent account?', style: AppTextStyles.bodyMedium),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () async {
              Navigator.pop(context);
              final provider = Provider.of<ParentAppProvider>(context, listen: false);
              await provider.logout();
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const ParentLoginScreen()),
                  (route) => false,
                );
              }
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}
