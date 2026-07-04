import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/reminder.dart';
import '../services/firestore_service.dart';
import '../services/notification_service.dart';
import '../theme.dart';
import '../widgets/category_badge.dart';

// Detailed view for a single reminder.
class ReminderDetailScreen extends StatelessWidget {
  final Reminder reminder;
  final FirestoreService firestoreService;

  const ReminderDetailScreen({
    super.key,
    required this.reminder,
    required this.firestoreService,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final categoryClr = AppTheme.categoryColor(reminder.category);
    final statusClr = AppTheme.statusColor(
      reminder.daysRemaining,
      reminder.isPaidThisCycle,
    );
    final currencyFormat = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 0,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reminder Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_rounded),
            tooltip: 'Edit',
            onPressed: () {
              Navigator.of(context).pop('edit');
            },
          ),
          IconButton(
            icon: Icon(
              Icons.delete_outline_rounded,
              color: theme.colorScheme.error,
            ),
            tooltip: 'Delete',
            onPressed: () => _confirmDelete(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    categoryClr.withAlpha(30),
                    categoryClr.withAlpha(10),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: categoryClr.withAlpha(40)),
              ),
              child: Column(
                children: [
                  CategoryBadge(
                    category: reminder.category,
                    fontSize: 13,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    reminder.title,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    currencyFormat.format(reminder.amount),
                    style: theme.textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: categoryClr,
                      letterSpacing: -1,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _InfoTile(
              icon: Icons.calendar_month_rounded,
              label: 'Due Date Range',
              value: 'Day ${reminder.dayStart} – Day ${reminder.dayEnd}',
              color: categoryClr,
            ),
            const SizedBox(height: 12),
            _InfoTile(
              icon: reminder.isPaidThisCycle
                  ? Icons.check_circle_rounded
                  : Icons.schedule_rounded,
              label: 'Status',
              value: _getStatusText(),
              color: statusClr,
            ),
            const SizedBox(height: 12),
            _InfoTile(
              icon: Icons.replay_rounded,
              label: 'Next Due',
              value: DateFormat('MMMM d, yyyy').format(reminder.nextDueDate),
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 12),
            _InfoTile(
              icon: Icons.access_time_rounded,
              label: 'Created',
              value: DateFormat('MMM d, yyyy – h:mm a')
                  .format(reminder.createdAt),
              color: theme.colorScheme.outline,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: reminder.isPaidThisCycle
                  ? OutlinedButton.icon(
                      onPressed: () => _markAsUnpaid(context),
                      icon: const Icon(Icons.undo_rounded),
                      label: const Text('Mark as Unpaid'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.overdueColor,
                        side: const BorderSide(color: AppTheme.overdueColor),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        textStyle: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                    )
                  : ElevatedButton.icon(
                      onPressed: () => _markAsPaid(context),
                      icon: const Icon(Icons.check_circle_rounded),
                      label: const Text('Mark as Paid'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.paidColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 2,
                        textStyle: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                    ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  String _getStatusText() {
    if (reminder.isPaidThisCycle) return 'Paid this cycle ✓';
    if (reminder.isOverdue) return 'Overdue! Payment window has passed';
    if (reminder.isDueNow) {
      return 'Due now — ${reminder.daysRemaining} days left in window';
    }
    return 'Upcoming — due in ${reminder.daysRemaining} days';
  }

  Future<void> _markAsPaid(BuildContext context) async {
    await firestoreService.markAsPaid(reminder.id);
    await NotificationService().cancelReminderNotifications(reminder.id);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${reminder.title} marked as paid'),
          backgroundColor: AppTheme.paidColor,
        ),
      );
      Navigator.of(context).pop('refresh');
    }
  }

  Future<void> _markAsUnpaid(BuildContext context) async {
    await firestoreService.markAsUnpaid(reminder.id);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${reminder.title} marked as unpaid'),
        ),
      );
      Navigator.of(context).pop('refresh');
    }
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Reminder'),
        content: Text(
          'Are you sure you want to delete "${reminder.title}"? '
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(ctx).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await firestoreService.deleteReminder(reminder.id);
      await NotificationService().cancelReminderNotifications(reminder.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${reminder.title} deleted')),
        );
        Navigator.of(context).pop('deleted');
      }
    }
  }
}

// Info detail display layout element.
class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withAlpha(10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withAlpha(30)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withAlpha(20),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withAlpha(140),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
