import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../providers/parent_app_provider.dart';
import '../../widgets/animated_card.dart';
import '../../widgets/empty_state_widget.dart';
import '../../widgets/status_badge.dart';
import 'notice_detail_screen.dart';

class NoticesScreen extends StatefulWidget {
  const NoticesScreen({super.key});

  @override
  State<NoticesScreen> createState() => _NoticesScreenState();
}

class _NoticesScreenState extends State<NoticesScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'All';
  String _searchQuery = '';
  final List<String> _categories = ['All', 'Unread', 'Important', 'Academic', 'Events', 'Holiday'];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ParentAppProvider>(context);
    final child = provider.selectedChild;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (!provider.hasNoticesData && provider.noticesError == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Notices & Announcements • ${child.name}', style: AppTextStyles.headingSmall),
          elevation: 0,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(color: AppColors.brandIndigo),
              const SizedBox(height: 16),
              Text(
                'Loading notices for ${child.name}...',
                style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textMuted),
              ),
            ],
          ),
        ),
      );
    }

    if (provider.noticesError != null && !provider.isNoticesLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Notices & Announcements • ${child.name}', style: AppTextStyles.headingSmall),
          elevation: 0,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.cloud_off_rounded, size: 64, color: AppColors.danger),
                const SizedBox(height: 16),
                Text(
                  'Unable to load notices. Please try again.',
                  style: AppTextStyles.headingSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  provider.noticesError!,
                  style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textMuted),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () => provider.loadNoticesForSelectedChild(),
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Retry'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.brandIndigo,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final allNotices = provider.notices;

    // 1. Search Query Filter
    final searchFilteredList = _searchQuery.isEmpty
        ? allNotices
        : allNotices.where((n) {
            final query = _searchQuery.toLowerCase();
            return n.title.toLowerCase().contains(query) ||
                n.fullDescription.toLowerCase().contains(query) ||
                n.publisherName.toLowerCase().contains(query);
          }).toList();

    // 2. Category Filter
    final filteredNotices = searchFilteredList.where((n) {
      if (_selectedCategory == 'All') return true;
      if (_selectedCategory == 'Unread') return !n.isRead;
      if (_selectedCategory == 'Important') return n.isImportant;
      return n.category.toLowerCase() == _selectedCategory.toLowerCase();
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text('Notices & Announcements • ${child.name}', style: AppTextStyles.headingSmall),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Search & Category Filter Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: _searchController,
              onChanged: (val) => setState(() => _searchQuery = val.trim()),
              style: AppTextStyles.bodyMedium,
              decoration: InputDecoration(
                hintText: 'Search notices, announcements...',
                hintStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.textMuted),
                prefixIcon: const Icon(Icons.search_rounded, color: AppColors.brandIndigo),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, color: AppColors.textMuted),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                filled: true,
                fillColor: isDark ? AppColors.darkSubSurface : AppColors.subSurface,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.border),
                ),
              ),
            ),
          ),

          // Filter Chips Scroll View
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: _categories.map((cat) {
                final isSelected = _selectedCategory == cat;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    selected: isSelected,
                    label: Text(cat),
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : AppColors.textPrimary,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    selectedColor: AppColors.brandIndigo,
                    backgroundColor: isDark ? AppColors.darkSubSurface : AppColors.subSurface,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    onSelected: (selected) {
                      setState(() {
                        _selectedCategory = cat;
                      });
                    },
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 8),

          Expanded(
            child: RefreshIndicator(
              onRefresh: () => provider.loadNoticesForSelectedChild(),
              color: AppColors.brandIndigo,
              child: filteredNotices.isEmpty
                  ? SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: SizedBox(
                        height: MediaQuery.of(context).size.height * 0.5,
                        child: EmptyStateWidget(
                          icon: Icons.campaign_outlined,
                          title: 'No notices available',
                          description: 'There are no active notices matching "$_selectedCategory".',
                        ),
                      ),
                    )
                  : ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                      padding: const EdgeInsets.all(16),
                    itemCount: filteredNotices.length,
                    itemBuilder: (context, index) {
                      final notice = filteredNotices[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: AnimatedCard(
                          onTap: () {
                            provider.markNoticeAsRead(notice.id);
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => NoticeDetailScreen(notice: notice)),
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(14.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        if (!notice.isRead) ...[
                                          Container(
                                            width: 8,
                                            height: 8,
                                            decoration: const BoxDecoration(
                                              color: AppColors.brandIndigo,
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                        ],
                                        StatusBadge(
                                          label: notice.category.toUpperCase(),
                                          type: notice.isImportant ? StatusType.danger : StatusType.info,
                                        ),
                                      ],
                                    ),
                                    Text(
                                      DateFormatter.formatShort(notice.date),
                                      style: AppTextStyles.caption,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  notice.title,
                                  style: AppTextStyles.headingSmall.copyWith(fontSize: 16),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  notice.shortDescription,
                                  style: AppTextStyles.bodyMedium,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('Published by ${notice.publisherName}', style: AppTextStyles.caption.copyWith(color: AppColors.textMuted)),
                                    if (notice.attachmentName != null || notice.attachmentUrl != null)
                                      Row(
                                        children: [
                                          const Icon(Icons.attach_file_rounded, size: 14, color: AppColors.brandIndigo),
                                          const SizedBox(width: 4),
                                          Text('Attachment', style: AppTextStyles.caption.copyWith(color: AppColors.brandIndigo, fontWeight: FontWeight.bold)),
                                        ],
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
