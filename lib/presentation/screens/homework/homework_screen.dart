import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../data/models/homework_model.dart';
import '../../../providers/parent_app_provider.dart';
import '../../widgets/animated_card.dart';
import '../../widgets/empty_state_widget.dart';
import '../../widgets/status_badge.dart';
import 'homework_detail_screen.dart';

class HomeworkScreen extends StatefulWidget {
  const HomeworkScreen({super.key});

  @override
  State<HomeworkScreen> createState() => _HomeworkScreenState();
}

class _HomeworkScreenState extends State<HomeworkScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _selectedSubjectFilter = 'All Subjects';
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ParentAppProvider>(context);
    final child = provider.selectedChild;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (!provider.hasHomeworkData && provider.homeworkError == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Homework Assignments', style: AppTextStyles.headingSmall),
          elevation: 0,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(color: AppColors.brandIndigo),
              const SizedBox(height: 16),
              Text(
                'Loading homework for ${child.name}...',
                style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textMuted),
              ),
            ],
          ),
        ),
      );
    }

    if (provider.homeworkError != null && !provider.isHomeworkLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Homework Assignments', style: AppTextStyles.headingSmall),
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
                  'Unable to load homework. Please try again.',
                  style: AppTextStyles.headingSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  provider.homeworkError!,
                  style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textMuted),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () => provider.loadHomeworkForSelectedChild(),
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

    final allHomework = provider.currentHomeworkList;
    final now = DateTime.now();

    // 1. Search Query Filter
    final searchFilteredList = _searchQuery.isEmpty
        ? allHomework
        : allHomework.where((h) {
            final query = _searchQuery.toLowerCase();
            return h.title.toLowerCase().contains(query) ||
                h.subject.toLowerCase().contains(query) ||
                h.teacherName.toLowerCase().contains(query);
          }).toList();

    // 2. Subject Filter
    final filteredList = _selectedSubjectFilter == 'All Subjects'
        ? searchFilteredList
        : searchFilteredList
            .where((h) => h.subject.toLowerCase() == _selectedSubjectFilter.toLowerCase())
            .toList();

    final pendingHomework = filteredList.where((h) => !h.isCompleted).toList();
    final completedHomework = filteredList.where((h) => h.isCompleted).toList();
    final overdueHomework = filteredList.where((h) => !h.isCompleted && h.dueDate.isBefore(now)).toList();

    final subjectsList = ['All Subjects', ...allHomework.map((h) => h.subject).toSet()];

    return Scaffold(
      appBar: AppBar(
        title: Text('Homework • ${child.name}', style: AppTextStyles.headingSmall),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: AppColors.brandIndigo,
          unselectedLabelColor: AppColors.textMuted,
          indicatorColor: AppColors.brandIndigo,
          indicatorWeight: 3,
          tabs: [
            Tab(text: 'Pending (${pendingHomework.length})'),
            Tab(text: 'Completed (${completedHomework.length})'),
            Tab(text: 'Overdue (${overdueHomework.length})'),
            Tab(text: 'All (${filteredList.length})'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Search & Subject Filter Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  onChanged: (val) => setState(() => _searchQuery = val.trim()),
                  style: AppTextStyles.bodyMedium,
                  decoration: InputDecoration(
                    hintText: 'Search by title, subject, or teacher...',
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
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(Icons.filter_list_rounded, size: 18, color: AppColors.textSecondary),
                    const SizedBox(width: 8),
                    Text('Subject:', style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkSubSurface : AppColors.subSurface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.border),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedSubjectFilter,
                            isExpanded: true,
                            icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.brandBlue),
                            style: AppTextStyles.bodyMedium,
                            items: subjectsList.map((sub) {
                              return DropdownMenuItem(value: sub, child: Text(sub));
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() {
                                  _selectedSubjectFilter = val;
                                });
                              }
                            },
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildHomeworkList(context, pendingHomework, 'No pending homework'),
                _buildHomeworkList(context, completedHomework, 'No completed homework yet'),
                _buildHomeworkList(context, overdueHomework, 'No overdue assignments'),
                _buildHomeworkList(context, filteredList, 'No homework assigned for ${child.name}'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHomeworkList(BuildContext context, List<HomeworkModel> items, String emptyTitle) {
    final provider = Provider.of<ParentAppProvider>(context, listen: false);
    if (items.isEmpty) {
      return RefreshIndicator(
        onRefresh: () => provider.loadHomeworkForSelectedChild(),
        color: AppColors.brandIndigo,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.5,
            child: EmptyStateWidget(
              icon: Icons.assignment_outlined,
              title: emptyTitle,
              description: 'Check back later for newly assigned tasks from class teachers.',
            ),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => provider.loadHomeworkForSelectedChild(),
      color: AppColors.brandIndigo,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
        padding: const EdgeInsets.all(16),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final hw = items[index];
        final isOverdue = !hw.isCompleted && hw.dueDate.isBefore(DateTime.now());

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: AnimatedCard(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => HomeworkDetailScreen(homework: hw)),
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.infoBg,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          hw.subject,
                          style: AppTextStyles.caption.copyWith(color: AppColors.brandBlue, fontWeight: FontWeight.bold),
                        ),
                      ),
                      Row(
                        children: [
                          if (hw.attachmentName != null || hw.attachmentUrl != null) ...[
                            const Icon(Icons.attach_file_rounded, size: 16, color: AppColors.brandIndigo),
                            const SizedBox(width: 6),
                          ],
                          StatusBadge(
                            label: hw.isCompleted
                                ? 'COMPLETED'
                                : (isOverdue ? 'OVERDUE' : 'PENDING'),
                            type: hw.isCompleted
                                ? StatusType.success
                                : (isOverdue ? StatusType.danger : StatusType.warning),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(hw.title, style: AppTextStyles.headingSmall.copyWith(fontSize: 16)),
                  const SizedBox(height: 6),
                  Text(hw.description, style: AppTextStyles.bodyMedium, maxLines: 2, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 12),
                  const Divider(height: 1),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.person_outline, size: 14, color: AppColors.textMuted),
                          const SizedBox(width: 4),
                          Text(hw.teacherName, style: AppTextStyles.caption),
                        ],
                      ),
                      Row(
                        children: [
                          const Icon(Icons.event_outlined, size: 14, color: AppColors.textMuted),
                          const SizedBox(width: 4),
                          Text('Due: ${DateFormatter.formatDayMonth(hw.dueDate)}', style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w600)),
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
  );
}
}
