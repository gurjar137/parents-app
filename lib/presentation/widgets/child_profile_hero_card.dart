import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../data/models/student_model.dart';
import '../../data/models/school_brand_model.dart';
import 'child_selector_sheet.dart';

class ChildProfileHeroCard extends StatelessWidget {
  final StudentModel child;
  final SchoolBrandModel branding;
  final int totalChildrenCount;

  const ChildProfileHeroCard({
    super.key,
    required this.child,
    required this.branding,
    required this.totalChildrenCount,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => ChildSelectorSheet.show(context),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: const LinearGradient(
            colors: [
              Color(0xFF10182D),
              Color(0xFF1A233A),
              Color(0xFF1E1B4B),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(
            color: Colors.white.withOpacity(0.12),
            width: 1,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x3510182D),
              blurRadius: 20,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: Stack(
            children: [
              // Subtle background glow accents (strictly clipped to avoid overflow)
              Positioned(
                top: -40,
                right: -40,
                child: Container(
                  width: 130,
                  height: 130,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppColors.brandIndigo.withOpacity(0.28),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: -50,
                left: -30,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppColors.brandBlue.withOpacity(0.15),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),

              // Main Card Content
              Padding(
                padding: const EdgeInsets.all(18.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top Section: Avatar + Name + Class Pill + Switch Child
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Profile Avatar
                        Container(
                          padding: const EdgeInsets.all(2.5),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withOpacity(0.85),
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: CircleAvatar(
                            radius: 27,
                            backgroundColor: const Color(0xFF2E3955),
                            backgroundImage: (child.avatarUrl.isNotEmpty && child.avatarUrl.startsWith('http'))
                                ? NetworkImage(child.avatarUrl)
                                : null,
                            child: (child.avatarUrl.isEmpty || !child.avatarUrl.startsWith('http'))
                                ? Text(
                                    child.name.isNotEmpty ? child.name[0].toUpperCase() : 'S',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  )
                                : null,
                          ),
                        ),

                        const SizedBox(width: 14),

                        // Child Name & Class Details
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      child.name,
                                      style: AppTextStyles.headingMedium.copyWith(
                                        color: Colors.white,
                                        fontSize: 17,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: -0.2,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (totalChildrenCount > 1) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.18),
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(color: Colors.white.withOpacity(0.25)),
                                      ),
                                      child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            'Switch',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 11,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                          SizedBox(width: 2),
                                          Icon(
                                            Icons.swap_horiz_rounded,
                                            color: Colors.white,
                                            size: 14,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 5),

                              // Class, Section & Roll Number Badges
                              Wrap(
                                spacing: 6,
                                runSpacing: 4,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      '${child.grade} • Sec ${child.section}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    'Roll #${child.rollNo}',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.8),
                                      fontSize: 11.5,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),
                    const Divider(color: Colors.white12, height: 1, thickness: 1),
                    const SizedBox(height: 12),

                    // Bottom Particulars (Responsive Wrap - Guarantees ZERO right-side overflow)
                    Wrap(
                      spacing: 14,
                      runSpacing: 8,
                      children: [
                        // Admission Number
                        _buildDetailItem(
                          icon: Icons.badge_outlined,
                          label: 'Adm: ${child.admissionNo}',
                        ),

                        // Father's Name (from authentic verified field)
                        if (child.displayFatherName != 'Not provided')
                          _buildDetailItem(
                            icon: Icons.person_outline_rounded,
                            label: 'Father: ${child.displayFatherName}',
                          ),

                        // School Name (from authentic school record)
                        _buildDetailItem(
                          icon: Icons.account_balance_outlined,
                          label: branding.schoolName,
                        ),

                        // Academic Session
                        if (child.academicYear.isNotEmpty)
                          _buildDetailItem(
                            icon: Icons.calendar_month_outlined,
                            label: child.academicYear,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailItem({required IconData icon, required String label}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white60, size: 13.5),
        const SizedBox(width: 4.5),
        Flexible(
          child: Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.85),
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
