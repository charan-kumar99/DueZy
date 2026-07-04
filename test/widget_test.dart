import 'package:flutter_test/flutter_test.dart';
import 'package:duezy/models/reminder.dart';

void main() {
  group('Reminder Model', () {
    test('fromString parses category correctly', () {
      expect(ReminderCategory.fromString('EMI'), ReminderCategory.emi);
      expect(
        ReminderCategory.fromString('Subscription'),
        ReminderCategory.subscription,
      );
      expect(ReminderCategory.fromString('Bill'), ReminderCategory.bill);
      expect(ReminderCategory.fromString('Custom'), ReminderCategory.custom);
      expect(
        ReminderCategory.fromString('unknown'),
        ReminderCategory.custom,
      );
    });

    test('copyWith creates a new instance with updated fields', () {
      final reminder = Reminder(
        id: 'test-1',
        title: 'Home Loan',
        amount: 25000,
        category: ReminderCategory.emi,
        dayStart: 5,
        dayEnd: 10,
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );

      final updated = reminder.copyWith(title: 'Car Loan', amount: 15000);
      expect(updated.title, 'Car Loan');
      expect(updated.amount, 15000);
      expect(updated.id, 'test-1'); // Unchanged
      expect(updated.dayStart, 5); // Unchanged
    });

    test('toFirestore produces correct map', () {
      final reminder = Reminder(
        id: 'test-1',
        title: 'Netflix',
        amount: 649,
        category: ReminderCategory.subscription,
        dayStart: 1,
        dayEnd: 3,
        createdAt: DateTime(2026, 7, 1),
        updatedAt: DateTime(2026, 7, 1),
      );

      final map = reminder.toFirestore();
      expect(map['title'], 'Netflix');
      expect(map['amount'], 649);
      expect(map['category'], 'Subscription');
      expect(map['dayStart'], 1);
      expect(map['dayEnd'], 3);
      expect(map['isPaidThisCycle'], false);
    });
  });
}
