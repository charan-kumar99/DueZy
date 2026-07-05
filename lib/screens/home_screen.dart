import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/reminder.dart';
import '../services/firestore_service.dart';
import '../services/notification_service.dart';
import '../widgets/reminder_card.dart';
import '../widgets/summary_card.dart';
import 'add_edit_reminder_screen.dart';
import 'reminder_detail_screen.dart';
import 'package:permission_handler/permission_handler.dart';

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

  StreamSubscription<List<Reminder>>? _remindersSubscription;
  List<Reminder> _remindersList = [];
  bool _isLoading = true;
  String? _error;

  int _logoTapCount = 0;
  DateTime? _lastTapTime;

  @override
  void initState() {
    super.initState();
    _fabController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    )..forward();

    // Listen to Firestore reminders stream and schedule notifications on changes
    _remindersSubscription = widget.firestoreService.getReminders().listen(
      (reminders) {
        if (mounted) {
          setState(() {
            _remindersList = reminders;
            _isLoading = false;
            _error = null;
          });
          _rescheduleNotifications(reminders);
        }
      },
      onError: (err) {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _error = err.toString();
          });
        }
      },
    );
  }

  @override
  void dispose() {
    _remindersSubscription?.cancel();
    _fabController.dispose();
    super.dispose();
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning ☀️';
    if (hour < 17) return 'Good afternoon 🌤️';
    return 'Good evening 🌙';
  }

  void _handleLogoTap() {
    final now = DateTime.now();
    if (_lastTapTime == null ||
        now.difference(_lastTapTime!) > const Duration(seconds: 2)) {
      _logoTapCount = 1;
    } else {
      _logoTapCount++;
    }
    _lastTapTime = now;

    if (_logoTapCount >= 5) {
      _logoTapCount = 0;
      _showTestNotificationDialog();
    }
  }

  void _showTestNotificationDialog() {
    final theme = Theme.of(context);
    
    String testTitle = 'Test DueZy Notification 🔔';
    String testBody = 'This is a test notification to verify scheduling works!';
    int selectedDelaySeconds = 5;
    
    DateTime? customDate;
    TimeOfDay? customTime;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Row(
                children: [
                  Icon(
                    Icons.bug_report_rounded,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  const Text('Notification Tester'),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Set up a custom reminder notification to verify the alarm scheduling works.',
                      style: TextStyle(fontSize: 13),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      decoration: const InputDecoration(
                        labelText: 'Notification Title',
                        border: OutlineInputBorder(),
                      ),
                      controller: TextEditingController(text: testTitle),
                      onChanged: (val) => testTitle = val,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      decoration: const InputDecoration(
                        labelText: 'Notification Body',
                        border: OutlineInputBorder(),
                      ),
                      controller: TextEditingController(text: testBody),
                      onChanged: (val) => testBody = val,
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Option 1: Quick Delay',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<int>(
                      initialValue: customDate == null ? selectedDelaySeconds : null,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Trigger in...',
                      ),
                      items: const [
                        DropdownMenuItem(value: 5, child: Text('5 Seconds')),
                        DropdownMenuItem(value: 10, child: Text('10 Seconds')),
                        DropdownMenuItem(value: 30, child: Text('30 Seconds')),
                        DropdownMenuItem(value: 60, child: Text('1 Minute')),
                        DropdownMenuItem(value: 300, child: Text('5 Minutes')),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setDialogState(() {
                            selectedDelaySeconds = val;
                            customDate = null;
                            customTime = null;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Option 2: Custom Date & Time',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.date_range_rounded),
                            label: Text(
                              customDate == null
                                  ? 'Select Date'
                                  : '${customDate!.day}/${customDate!.month}/${customDate!.year}',
                            ),
                            onPressed: () async {
                              final pickedDate = await showDatePicker(
                                context: context,
                                initialDate: DateTime.now(),
                                firstDate: DateTime.now(),
                                lastDate: DateTime.now().add(const Duration(days: 365)),
                              );
                              if (pickedDate != null) {
                                setDialogState(() {
                                  customDate = pickedDate;
                                });
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.access_time_rounded),
                            label: Text(
                              customTime == null
                                  ? 'Select Time'
                                  : customTime!.format(context),
                            ),
                            onPressed: () async {
                              final pickedTime = await showTimePicker(
                                context: context,
                                initialTime: TimeOfDay.now(),
                              );
                              if (pickedTime != null) {
                                setDialogState(() {
                                  customTime = pickedTime;
                                });
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () async {
                    final testId = DateTime.now().millisecondsSinceEpoch & 0x7FFFFFFF;
                    try {
                      await NotificationService().showImmediateNotification(
                        id: testId,
                        title: testTitle,
                        body: testBody,
                      );
                      if (context.mounted) {
                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('Immediate notification triggered!'),
                            backgroundColor: theme.colorScheme.secondary,
                          ),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Failed to show notification: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  },
                  child: const Text('Trigger Now'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    DateTime scheduleTime;
                    if (customDate != null && customTime != null) {
                      scheduleTime = DateTime(
                        customDate!.year,
                        customDate!.month,
                        customDate!.day,
                        customTime!.hour,
                        customTime!.minute,
                      );
                    } else {
                      scheduleTime = DateTime.now().add(Duration(seconds: selectedDelaySeconds));
                    }

                    if (scheduleTime.isBefore(DateTime.now())) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Cannot schedule a notification in the past!'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }

                    final testId = DateTime.now().millisecondsSinceEpoch & 0x7FFFFFFF;
                    final diagnostics = await NotificationService().scheduleTestNotification(
                      id: testId,
                      title: testTitle,
                      body: testBody,
                      scheduledDateTime: scheduleTime,
                    );

                    if (context.mounted) {
                      Navigator.of(context).pop(); // Close tester dialog

                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          final status = diagnostics['status'];
                          final isExact = status == 'success_exact';
                          final isFailed = status == 'failed';

                          return AlertDialog(
                            title: Row(
                              children: [
                                Icon(
                                  isFailed ? Icons.error_rounded : Icons.info_rounded,
                                  color: isFailed ? Colors.red : (isExact ? Colors.green : Colors.orange),
                                ),
                                const SizedBox(width: 8),
                                const Text('Scheduler Diagnostics'),
                              ],
                            ),
                            content: SingleChildScrollView(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Status: ${status?.toUpperCase()}',
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 8),
                                  Text('Timezone set: ${diagnostics['timezone']}'),
                                  Text('Phone Time: ${diagnostics['localNow']}'),
                                  Text('Timezone Time: ${diagnostics['tzNow']}'),
                                  Text('Scheduled for: ${diagnostics['scheduledTZDateTime']}'),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Exact Alarm Permission: ${diagnostics['exactAlarmGranted'] == 'true' ? "✅ GRANTED" : "❌ DENIED / NOT GRANTED"}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: diagnostics['exactAlarmGranted'] == 'true' ? Colors.green : Colors.red,
                                    ),
                                  ),
                                  if (diagnostics['exactAlarmGranted'] != 'true') ...[
                                    const SizedBox(height: 8),
                                    SizedBox(
                                      width: double.infinity,
                                      child: ElevatedButton.icon(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: theme.colorScheme.errorContainer,
                                          foregroundColor: theme.colorScheme.onErrorContainer,
                                        ),
                                        icon: const Icon(Icons.settings_suggest_rounded),
                                        label: const Text('Grant Alarm Permission'),
                                        onPressed: () {
                                          openAppSettings();
                                        },
                                      ),
                                    ),
                                  ],
                                  const Divider(),
                                  if (status == 'success_inexact_fallback') ...[
                                    const Text(
                                      '⚠️ Warning: Exact alarms failed, so it fell back to Inexact. Inexact alarms are heavily delayed by Android (up to 15+ minutes) to save battery, which is why 5/10 seconds triggers do not show up immediately!',
                                      style: TextStyle(color: Colors.orange, fontSize: 13),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Error: ${diagnostics['exact_error']}',
                                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                                    ),
                                  ] else if (isExact) ...[
                                    const Text(
                                      '✅ Exact alarm scheduled successfully! If it still does not fire in 10 seconds, check if your phone battery saver is silencing or delaying it in the background.',
                                      style: TextStyle(color: Colors.green, fontSize: 13),
                                    ),
                                  ] else if (isFailed) ...[
                                    Text('Exact Alarm Error: ${diagnostics['exact_error']}', style: const TextStyle(fontSize: 11, color: Colors.red)),
                                    Text('Inexact Alarm Error: ${diagnostics['inexact_error']}', style: const TextStyle(fontSize: 11, color: Colors.red)),
                                  ]
                                ],
                              ),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(),
                                child: const Text('OK'),
                              ),
                            ],
                          );
                        },
                      );
                    }
                  },
                  child: const Text('Schedule'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = widget.themeMode == ThemeMode.dark ||
        (widget.themeMode == ThemeMode.system &&
            theme.brightness == Brightness.dark);

    return Scaffold(
      appBar: AppBar(
        title: GestureDetector(
          onTap: _handleLogoTap,
          behavior: HitTestBehavior.opaque,
          child: Row(
            mainAxisSize: MainAxisSize.min,
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
      body: _buildBody(theme),
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

  Widget _buildBody(ThemeData theme) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null) {
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
                _error!,
                style: theme.textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    final allReminders = _remindersList;
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
