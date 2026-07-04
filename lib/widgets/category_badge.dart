import 'package:flutter/material.dart';
import '../models/reminder.dart';
import '../theme.dart';

// Small colored chip that displays the reminder's category.
class CategoryBadge extends StatelessWidget {
  final ReminderCategory category;
  final double fontSize;

  const CategoryBadge({
    super.key,
    required this.category,
    this.fontSize = 11,
  });

  @override
  Widget build(BuildContext context) {
    final color = AppTheme.categoryColor(category);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withAlpha(80), width: 1),
      ),
      child: Text(
        category.label,
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}
