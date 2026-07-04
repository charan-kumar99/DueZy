import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/reminder.dart';

// Firestore CRUD operations scoped to user's UID.
class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String uid;

  FirestoreService({required this.uid});

  // Reference to user reminders collection.
  CollectionReference<Map<String, dynamic>> get _remindersRef =>
      _db.collection('users').doc(uid).collection('reminders');

  // Stream of reminders ordered by starting day.
  Stream<List<Reminder>> getReminders() {
    return _remindersRef
        .orderBy('dayStart', descending: false)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Reminder.fromFirestore(doc)).toList());
  }

  // Add a new reminder.
  Future<String> addReminder(Reminder reminder) async {
    final docRef = await _remindersRef.add(reminder.toFirestore());
    return docRef.id;
  }

  // Update an existing reminder.
  Future<void> updateReminder(Reminder reminder) async {
    await _remindersRef.doc(reminder.id).update({
      ...reminder.toFirestore(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Delete a reminder.
  Future<void> deleteReminder(String reminderId) async {
    await _remindersRef.doc(reminderId).delete();
  }

  // Mark reminder as paid for current cycle.
  Future<void> markAsPaid(String reminderId) async {
    await _remindersRef.doc(reminderId).update({
      'isPaidThisCycle': true,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Mark reminder as unpaid (manual undo).
  Future<void> markAsUnpaid(String reminderId) async {
    await _remindersRef.doc(reminderId).update({
      'isPaidThisCycle': false,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Reset paid status for all reminders.
  Future<void> resetAllPaidStatus() async {
    final snapshot = await _remindersRef.get();
    final batch = _db.batch();

    for (final doc in snapshot.docs) {
      batch.update(doc.reference, {
        'isPaidThisCycle': false,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }

    await batch.commit();
  }
}
