import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/reminder.dart';
import '../theme.dart';

// Card summarizing total, paid, and pending bills.
class SummaryCard extends StatelessWidget {
  final List<Reminder> reminders;

  const SummaryCard({super.key, required this.reminders});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currencyFormat = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 0,
    );

    final totalAmount = reminders.fold<double>(
      0,
      (sum, r) => sum + r.amount,
    );
    final paidReminders = reminders.where((r) => r.isPaidThisCycle).toList();
    final paidAmount = paidReminders.fold<double>(
      0,
      (sum, r) => sum + r.amount,
    );
    final pendingAmount = totalAmount - paidAmount;
    final pendingCount = reminders.length - paidReminders.length;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF5C6BC0),
            Color(0xFF7C4DFF),
            Color(0xFFAB47BC),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.seedColor.withAlpha(60),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      DateFormat('MMMM yyyy').format(DateTime.now()),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withAlpha(200),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(25),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${paidReminders.length}/${reminders.length} paid',
                        style: GoogleFonts.spaceMono(
                          textStyle: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'Total Due',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.white.withAlpha(180),
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  currencyFormat.format(totalAmount),
                  style: GoogleFonts.spaceMono(
                    textStyle: theme.textTheme.headlineLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -1,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: _StatColumn(
                        label: 'Paid',
                        value: currencyFormat.format(paidAmount),
                        icon: Icons.check_circle_outline_rounded,
                        color: const Color(0xFF69F0AE),
                      ),
                    ),
                    Container(
                      height: 40,
                      width: 1,
                      color: Colors.white.withAlpha(40),
                    ),
                    Expanded(
                      child: _StatColumn(
                        label: 'Pending ($pendingCount)',
                        value: currencyFormat.format(pendingAmount),
                        icon: Icons.schedule_rounded,
                        color: const Color(0xFFFFD740),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Single column displaying a label, value, and icon.
class _StatColumn extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatColumn({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.white.withAlpha(160),
                    fontSize: 11,
                  ),
                ),
                Text(
                  value,
                  style: GoogleFonts.spaceMono(
                    textStyle: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
