import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/reminder.dart';
import '../services/firestore_service.dart';
import '../services/notification_service.dart';
import '../widgets/reminder_card.dart';
import '../widgets/summary_card.dart';
import 'add_edit_reminder_screen.dart';
import 'reminder_detail_screen.dart';

// The main home screen of Duezy.
class HomeScreen extends StatefulWidget {
  final FirestoreService firestoreService;
  final ThemeMode themeMode;
  final VoidCallback onThemeToggle;

  const HomeScreen({
    super.key,
    required this.firestoreService,
    required this.themeMode,
    required this.onThemeToggle,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  ReminderCategory? _selectedCategory;
  late final AnimationController _fabController;

  @override
  void initState() {
    super.initState();
    _fabController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    )..forward();
  }

  @override
  void dispose() {
    _fabController.dispose();
    super.dispose();
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning ☀️';
    if (hour < 17) return 'Good afternoon 🌤️';
    return 'Good evening 🌙';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = widget.themeMode == ThemeMode.dark ||
        (widget.themeMode == ThemeMode.system &&
            theme.brightness == Brightness.dark);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF5C6BC0), Color(0xFF7C4DFF)],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.notifications_active_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'DueZy',
              style: GoogleFonts.agbalumo(
                fontSize: 24,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
              isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
            ),
            tooltip: isDark ? 'Light Mode' : 'Dark Mode',
            onPressed: widget.onThemeToggle,
          ),
        ],
      ),
      body: StreamBuilder<List<Reminder>>(
        stream: widget.firestoreService.getReminders(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.error_outline_rounded,
                      size: 64,
                      color: theme.colorScheme.error.withAlpha(160),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Something went wrong',
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${snapshot.error}',
                      style: theme.textTheme.bodySmall,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          final allReminders = snapshot.data ?? [];

          _rescheduleNotifications(allReminders);

          final filteredReminders = _selectedCategory == null
              ? allReminders
              : allReminders
                  .where((r) => r.category == _selectedCategory)
                  .toList();

          filteredReminders.sort((a, b) {
            if (a.isPaidThisCycle != b.isPaidThisCycle) {
              return a.isPaidThisCycle ? 1 : -1;
            }
            return a.daysRemaining.compareTo(b.daysRemaining);
          });

          return RefreshIndicator(
            onRefresh: () async {
              await Future.delayed(const Duration(milliseconds: 500));
            },
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _getGreeting(),
                          style: GoogleFonts.tangerine(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Track & Settle Bills',
                          style: GoogleFonts.russoOne(
                            textStyle: theme.textTheme.headlineSmall?.copyWith(
                              fontStyle: FontStyle.italic,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (allReminders.isNotEmpty)
                  SliverToBoxAdapter(
                    child: SummaryCard(reminders: allReminders),
                  ),
                SliverToBoxAdapter(
                  child: _CategoryFilters(
                    selected: _selectedCategory,
                    onSelected: (cat) {
                      setState(() => _selectedCategory = cat);
                    },
                  ),
                ),
                if (filteredReminders.isEmpty)
                  SliverFillRemaining(
                    child: _EmptyState(
                      hasReminders: allReminders.isNotEmpty,
                      selectedCategory: _selectedCategory,
                    ),
                  ),
                if (filteredReminders.isNotEmpty)
                  SliverPadding(
                    padding: const EdgeInsets.only(bottom: 80),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final reminder = filteredReminders[index];
                          return ReminderCard(
                            reminder: reminder,
                            onTap: () => _openDetail(reminder),
                            onMarkPaid: () => widget.firestoreService.markAsPaid(reminder.id),
                            onMarkUnpaid: () => widget.firestoreService.markAsUnpaid(reminder.id),
                          );
                        },
                        childCount: filteredReminders.length,
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: ScaleTransition(
        scale: CurvedAnimation(
          parent: _fabController,
          curve: Curves.elasticOut,
        ),
        child: FloatingActionButton.extended(
          onPressed: _addReminder,
          icon: const Icon(Icons.add_rounded),
          label: const Text('Add Reminder'),
        ),
      ),
    );
  }

  void _rescheduleNotifications(List<Reminder> reminders) {
    NotificationService().scheduleAllReminders(reminders);
  }

  Future<void> _addReminder() async {
    await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => AddEditReminderScreen(
          firestoreService: widget.firestoreService,
        ),
      ),
    );
  }

  Future<void> _openDetail(Reminder reminder) async {
    final result = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => ReminderDetailScreen(
          reminder: reminder,
          firestoreService: widget.firestoreService,
        ),
      ),
    );

    if (result == 'edit' && mounted) {
      await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (_) => AddEditReminderScreen(
            firestoreService: widget.firestoreService,
            existingReminder: reminder,
          ),
        ),
      );
    }
  }
}

// Category filters horizontal scroll row.
class _CategoryFilters extends StatelessWidget {
  final ReminderCategory? selected;
  final ValueChanged<ReminderCategory?> onSelected;

  const _CategoryFilters({
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _FilterChip(
              label: 'All',
              isSelected: selected == null,
              color: theme.colorScheme.primary,
              onTap: () => onSelected(null),
            ),
            const SizedBox(width: 8),
            ...ReminderCategory.values.map((cat) {
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _FilterChip(
                  label: cat.label,
                  isSelected: selected == cat,
                  color: _getCategoryColor(cat),
                  onTap: () => onSelected(selected == cat ? null : cat),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Color _getCategoryColor(ReminderCategory cat) {
    switch (cat) {
      case ReminderCategory.emi:
        return const Color(0xFF5C6BC0);
      case ReminderCategory.subscription:
        return const Color(0xFF26A69A);
      case ReminderCategory.bill:
        return const Color(0xFFFFA726);
      case ReminderCategory.custom:
        return const Color(0xFFAB47BC);
    }
  }
}

// Custom selectable chip.
class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? color.withAlpha(25) : theme.cardTheme.color,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? color : theme.colorScheme.outlineVariant.withAlpha(80),
              width: isSelected ? 1.5 : 1,
            ),
            boxShadow: [
              if (isSelected)
                BoxShadow(
                  color: color.withAlpha(15),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
            ],
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? color : theme.colorScheme.onSurface.withAlpha(160),
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}

// Displayed when no reminders match selected filter or list is empty.
class _EmptyState extends StatelessWidget {
  final bool hasReminders;
  final ReminderCategory? selectedCategory;

  const _EmptyState({
    required this.hasReminders,
    this.selectedCategory,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withAlpha(15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                hasReminders
                    ? Icons.filter_list_off_rounded
                    : Icons.notifications_none_rounded,
                size: 56,
                color: theme.colorScheme.primary.withAlpha(120),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              hasReminders
                  ? 'No ${selectedCategory?.label ?? ""} reminders'
                  : 'No reminders yet',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              hasReminders
                  ? 'Try selecting a different category filter'
                  : 'Tap the button below to add your first\nbill or EMI reminder',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withAlpha(140),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
