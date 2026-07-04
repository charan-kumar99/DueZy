import 'package:cloud_firestore/cloud_firestore.dart';

// Categories for reminders.
enum ReminderCategory {
  emi('EMI'),
  subscription('Subscription'),
  bill('Bill'),
  custom('Custom');

  final String label;
  const ReminderCategory(this.label);

  // Parse a category from its string representation.
  static ReminderCategory fromString(String value) {
    return ReminderCategory.values.firstWhere(
      (cat) => cat.label.toLowerCase() == value.toLowerCase(),
      orElse: () => ReminderCategory.custom,
    );
  }
}

// Model representing a recurring bill or EMI reminder.
class Reminder {
  final String id;
  final String title;
  final double amount;
  final ReminderCategory category;
  final int dayStart;
  final int dayEnd;
  final bool isPaidThisCycle;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Reminder({
    required this.id,
    required this.title,
    required this.amount,
    required this.category,
    required this.dayStart,
    required this.dayEnd,
    this.isPaidThisCycle = false,
    required this.createdAt,
    required this.updatedAt,
  });

  // Create a Reminder from Firestore document snapshot.
  factory Reminder.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return Reminder(
      id: doc.id,
      title: data['title'] as String,
      amount: (data['amount'] as num).toDouble(),
      category: ReminderCategory.fromString(data['category'] as String),
      dayStart: data['dayStart'] as int,
      dayEnd: data['dayEnd'] as int,
      isPaidThisCycle: data['isPaidThisCycle'] as bool? ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  // Convert this reminder to a Firestore map.
  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'amount': amount,
      'category': category.label,
      'dayStart': dayStart,
      'dayEnd': dayEnd,
      'isPaidThisCycle': isPaidThisCycle,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  // Next due date for current or upcoming month.
  DateTime get nextDueDate {
    final now = DateTime.now();
    if (now.day <= dayEnd) {
      return DateTime(now.year, now.month, dayStart);
    }
    final nextMonth = now.month == 12 ? 1 : now.month + 1;
    final nextYear = now.month == 12 ? now.year + 1 : now.year;
    return DateTime(nextYear, nextMonth, dayStart);
  }

  // Days remaining until due.
  int get daysRemaining {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    if (isPaidThisCycle) {
      final nextCycleStart = nextDueDate;
      if (nextCycleStart.isAfter(today)) {
        return nextCycleStart.difference(today).inDays;
      }
      return 0;
    }

    if (now.day >= dayStart && now.day <= dayEnd) {
      return dayEnd - now.day;
    }

    if (now.day < dayStart) {
      return dayStart - now.day;
    }

    return nextDueDate.difference(today).inDays;
  }

  // Check if reminder is overdue.
  bool get isOverdue {
    if (isPaidThisCycle) return false;
    final now = DateTime.now();
    return now.day > dayEnd;
  }

  // Check if today is within the payment window.
  bool get isDueNow {
    if (isPaidThisCycle) return false;
    final now = DateTime.now();
    return now.day >= dayStart && now.day <= dayEnd;
  }

  // Create a copy with optional overrides.
  Reminder copyWith({
    String? id,
    String? title,
    double? amount,
    ReminderCategory? category,
    int? dayStart,
    int? dayEnd,
    bool? isPaidThisCycle,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Reminder(
      id: id ?? this.id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      dayStart: dayStart ?? this.dayStart,
      dayEnd: dayEnd ?? this.dayEnd,
      isPaidThisCycle: isPaidThisCycle ?? this.isPaidThisCycle,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() => 'Reminder(id: $id, title: $title, amount: $amount, '
      'category: ${category.label}, days: $dayStart–$dayEnd, '
      'paid: $isPaidThisCycle)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Reminder && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
