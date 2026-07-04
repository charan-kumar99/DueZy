import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/reminder.dart';
import '../theme.dart';
import 'category_badge.dart';

// Card displaying quick summary and action to mark a reminder as paid.
class ReminderCard extends StatefulWidget {
  final Reminder reminder;
  final VoidCallback onTap;
  final Future<void> Function()? onMarkPaid;
  final Future<void> Function()? onMarkUnpaid;

  const ReminderCard({
    super.key,
    required this.reminder,
    required this.onTap,
    this.onMarkPaid,
    this.onMarkUnpaid,
  });

  @override
  State<ReminderCard> createState() => _ReminderCardState();
}

class _ReminderCardState extends State<ReminderCard> {
  bool _isActionRunning = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final categoryClr = AppTheme.categoryColor(widget.reminder.category);
    final currencyFormat = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 0,
    );

    final daysLeft = widget.reminder.daysRemaining;
    final statusClr = AppTheme.statusColor(daysLeft, widget.reminder.isPaidThisCycle);

    final shadows = widget.reminder.isPaidThisCycle
        ? <BoxShadow>[]
        : [
            BoxShadow(
              color: categoryClr.withAlpha(20),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: AnimatedScale(
        scale: _isActionRunning ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 150),
        child: Container(
          decoration: BoxDecoration(
            color: widget.reminder.isPaidThisCycle
                ? theme.cardTheme.color?.withAlpha(120)
                : theme.cardTheme.color,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: widget.reminder.isPaidThisCycle
                  ? AppTheme.paidColor.withAlpha(40)
                  : categoryClr.withAlpha(60),
              width: 1.2,
            ),
            boxShadow: shadows,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: widget.onTap,
                splashColor: categoryClr.withAlpha(20),
                highlightColor: categoryClr.withAlpha(10),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: widget.reminder.isPaidThisCycle
                              ? AppTheme.paidColor.withAlpha(20)
                              : categoryClr.withAlpha(20),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(
                          _getCategoryIcon(widget.reminder.category),
                          color: widget.reminder.isPaidThisCycle
                              ? AppTheme.paidColor
                              : categoryClr,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.reminder.title,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                decoration: widget.reminder.isPaidThisCycle
                                    ? TextDecoration.lineThrough
                                    : null,
                                color: widget.reminder.isPaidThisCycle
                                    ? theme.textTheme.titleMedium?.color
                                        ?.withAlpha(120)
                                    : null,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                CategoryBadge(
                                  category: widget.reminder.category,
                                  fontSize: 10,
                                ),
                                const SizedBox(width: 8),
                                Icon(
                                  Icons.calendar_today_rounded,
                                  size: 11,
                                  color: theme.colorScheme.onSurface
                                      .withAlpha(120),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Day ${widget.reminder.dayStart}–${widget.reminder.dayEnd}',
                                  style: GoogleFonts.spaceMono(
                                    textStyle: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurface
                                          .withAlpha(140),
                                      fontWeight: FontWeight.w700,
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            _StatusLabel(
                              reminder: widget.reminder,
                              statusColor: statusClr,
                              daysLeft: daysLeft,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            currencyFormat.format(widget.reminder.amount),
                            style: GoogleFonts.spaceMono(
                              textStyle: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: widget.reminder.isPaidThisCycle
                                    ? AppTheme.paidColor
                                    : theme.colorScheme.onSurface,
                                letterSpacing: -0.8,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          _QuickActionCheckbox(
                            isPaid: widget.reminder.isPaidThisCycle,
                            color: categoryClr,
                            onToggle: _isActionRunning
                                ? null
                                : () async {
                                    setState(() => _isActionRunning = true);
                                    if (widget.reminder.isPaidThisCycle) {
                                      if (widget.onMarkUnpaid != null) {
                                        await widget.onMarkUnpaid!();
                                      }
                                    } else {
                                      if (widget.onMarkPaid != null) {
                                        await widget.onMarkPaid!();
                                      }
                                    }
                                    if (mounted) {
                                      setState(() => _isActionRunning = false);
                                    }
                                  },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  IconData _getCategoryIcon(ReminderCategory category) {
    switch (category) {
      case ReminderCategory.emi:
        return Icons.account_balance_rounded;
      case ReminderCategory.subscription:
        return Icons.subscriptions_rounded;
      case ReminderCategory.bill:
        return Icons.receipt_long_rounded;
      case ReminderCategory.custom:
        return Icons.tune_rounded;
    }
  }
}

// Custom checkbox for quick marking as paid.
class _QuickActionCheckbox extends StatelessWidget {
  final bool isPaid;
  final Color color;
  final VoidCallback? onToggle;

  const _QuickActionCheckbox({
    required this.isPaid,
    required this.color,
    this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onToggle,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: isPaid
              ? AppTheme.paidColor.withAlpha(25)
              : color.withAlpha(12),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isPaid
                ? AppTheme.paidColor
                : color.withAlpha(80),
            width: 1.5,
          ),
        ),
        child: isPaid
            ? const Icon(
                Icons.check_rounded,
                size: 20,
                color: AppTheme.paidColor,
              )
            : Icon(
                Icons.circle_outlined,
                size: 18,
                color: color.withAlpha(180),
              ),
      ),
    );
  }
}

// Text badge showing current payment status.
class _StatusLabel extends StatelessWidget {
  final Reminder reminder;
  final Color statusColor;
  final int daysLeft;

  const _StatusLabel({
    required this.reminder,
    required this.statusColor,
    required this.daysLeft,
  });

  @override
  Widget build(BuildContext context) {
    String text;
    IconData icon;

    if (reminder.isPaidThisCycle) {
      text = 'Paid this month';
      icon = Icons.check_circle_rounded;
    } else if (reminder.isOverdue) {
      text = 'Overdue by ${daysLeft.abs()} days';
      icon = Icons.warning_rounded;
    } else if (reminder.isDueNow) {
      text = '$daysLeft days remaining';
      icon = Icons.notifications_active_rounded;
    } else {
      text = 'Starts in $daysLeft days';
      icon = Icons.schedule_rounded;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: statusColor),
        const SizedBox(width: 6),
        Text(
          text,
          style: TextStyle(
            color: statusColor,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
