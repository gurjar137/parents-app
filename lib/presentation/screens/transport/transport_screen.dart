import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../providers/parent_app_provider.dart';
import '../../widgets/animated_card.dart';
import '../../widgets/status_badge.dart';

class TransportScreen extends StatelessWidget {
  const TransportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ParentAppProvider>(context);
    final child = provider.selectedChild;
    final transport = provider.currentTransport;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (!provider.isChildLinked || transport == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text('School Bus Tracking', style: AppTextStyles.headingSmall),
          elevation: 0,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.directions_bus_outlined, size: 64, color: AppColors.textMuted),
                const SizedBox(height: 16),
                Text('Transport not available', style: AppTextStyles.headingSmall),
                const SizedBox(height: 8),
                Text(
                  'Bus route and tracking details is not available in the Parents App yet. Please contact the school office.',
                  style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textMuted),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('${child.name}\'s School Bus', style: AppTextStyles.headingSmall),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Bus Live Overview Banner
            AnimatedCard(
              backgroundColor: AppColors.primary,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: const BoxDecoration(
                              color: Colors.white24,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.directions_bus_rounded, color: Colors.white, size: 24),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(transport.busNumber, style: AppTextStyles.headingSmall.copyWith(color: Colors.white, fontSize: 16)),
                              Text(transport.routeName, style: AppTextStyles.caption.copyWith(color: Colors.white70)),
                            ],
                          ),
                        ],
                      ),
                      const StatusBadge(label: 'LIVE TRACK', type: StatusType.success),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(color: Colors.white24),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Bus Status', style: AppTextStyles.caption.copyWith(color: Colors.white70)),
                          Text(transport.currentStatus, style: AppTextStyles.headingSmall.copyWith(color: Colors.white, fontSize: 14)),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('Est. Arrival', style: AppTextStyles.caption.copyWith(color: Colors.white70)),
                          Text(transport.estimatedArrival, style: AppTextStyles.headingSmall.copyWith(color: AppColors.success, fontSize: 16)),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Driver & Staff Contact Card
            AnimatedCard(
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 22,
                    backgroundColor: AppColors.subSurface,
                    child: Icon(Icons.person_rounded, color: AppColors.brandIndigo),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(transport.driverName, style: AppTextStyles.headingSmall.copyWith(fontSize: 15)),
                        Text('Bus In-Charge • Helper: ${transport.helperName}', style: AppTextStyles.caption),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.phone_rounded, color: AppColors.success),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Calling ${transport.driverName} (${transport.driverPhone})...')),
                      );
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Route Timeline / Stops Stepper
            Text('Bus Route & Scheduled Stops', style: AppTextStyles.headingSmall),
            const SizedBox(height: 12),

            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: transport.routeStops.length,
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final stop = transport.routeStops[index];
                return AnimatedCard(
                  backgroundColor: stop.isStudentStop
                      ? (isDark ? AppColors.darkInfoBg : AppColors.infoBg)
                      : null,
                  border: stop.isStudentStop
                      ? Border.all(color: AppColors.brandBlue, width: 1.5)
                      : null,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      Icon(
                        stop.isCompleted ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                        color: stop.isCompleted ? AppColors.success : AppColors.textMuted,
                        size: 20,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  stop.stopName,
                                  style: AppTextStyles.headingSmall.copyWith(fontSize: 14),
                                ),
                                if (stop.isStudentStop) ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppColors.brandBlue,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Text('Your Stop', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                                  ),
                                ],
                              ],
                            ),
                            Text('Pickup: ${stop.morningPickupTime} • Drop: ${stop.afternoonDropTime}', style: AppTextStyles.caption),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
