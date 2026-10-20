import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import 'friendly_error_view.dart';

/// Loading / error / content switch for data loaded from the school.
/// An error is never rendered as an empty list.
class LoadStateView extends StatelessWidget {
  final bool isLoading;
  final String? error;
  final bool hasData;
  final Future<void> Function() onRetry;
  final WidgetBuilder builder;

  const LoadStateView({
    super.key,
    required this.isLoading,
    required this.error,
    required this.hasData,
    required this.onRetry,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    if (error != null && !isLoading) {
      return FriendlyErrorView(
        title: 'Could not load',
        message: error!,
        onRetry: () => onRetry(),
      );
    }
    if (!hasData) {
      return const Center(child: CircularProgressIndicator(color: AppColors.brandIndigo));
    }
    return RefreshIndicator(onRefresh: onRetry, child: builder(context));
  }
}
