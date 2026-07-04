import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show FilteringTextInputFormatter;
import '../models/reminder.dart';
import '../services/firestore_service.dart';
import '../theme.dart';

// Screen for creating or editing a reminder.
class AddEditReminderScreen extends StatefulWidget {
  final FirestoreService firestoreService;
  final Reminder? existingReminder;

  const AddEditReminderScreen({
    super.key,
    required this.firestoreService,
    this.existingReminder,
  });

  bool get isEditing => existingReminder != null;

  @override
  State<AddEditReminderScreen> createState() => _AddEditReminderScreenState();
}

class _AddEditReminderScreenState extends State<AddEditReminderScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();

  ReminderCategory _category = ReminderCategory.bill;
  int _dayStart = 1;
  int _dayEnd = 5;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.isEditing) {
      final r = widget.existingReminder!;
      _titleController.text = r.title;
      _amountController.text = r.amount.toStringAsFixed(0);
      _category = r.category;
      _dayStart = r.dayStart;
      _dayEnd = r.dayEnd;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final categoryClr = AppTheme.categoryColor(_category);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Edit Reminder' : 'Add Reminder'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    categoryClr.withAlpha(25),
                    categoryClr.withAlpha(8),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: categoryClr.withAlpha(40)),
              ),
              child: Column(
                children: [
                  Icon(
                    _getCategoryIcon(),
                    size: 40,
                    color: categoryClr,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.isEditing ? 'Edit Reminder' : 'New Reminder',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: categoryClr,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            Text(
              'Title',
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _titleController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                hintText: 'e.g. Home Loan EMI, Netflix, Electricity',
                prefixIcon: Icon(Icons.edit_note_rounded),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a title';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            Text(
              'Amount (₹)',
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                hintText: 'e.g. 15000',
                prefixIcon: Icon(Icons.currency_rupee_rounded),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter an amount';
                }
                final amount = double.tryParse(value);
                if (amount == null || amount <= 0) {
                  return 'Amount must be greater than 0';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            Text(
              'Category',
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: theme.inputDecorationTheme.fillColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: DropdownButtonFormField<ReminderCategory>(
                initialValue: _category,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.category_rounded),
                  border: InputBorder.none,
                ),
                borderRadius: BorderRadius.circular(12),
                items: ReminderCategory.values.map((cat) {
                  return DropdownMenuItem(
                    value: cat,
                    child: Row(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: AppTheme.categoryColor(cat),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(cat.label),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _category = value);
                  }
                },
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Reminder Date Range',
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'You\'ll be notified daily from Day $_dayStart to Day $_dayEnd each month',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withAlpha(140),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _DayPicker(
                    label: 'From Day',
                    value: _dayStart,
                    min: 1,
                    max: 28,
                    onChanged: (val) {
                      setState(() {
                        _dayStart = val;
                        if (_dayEnd < _dayStart) {
                          _dayEnd = _dayStart;
                        }
                      });
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Icon(
                    Icons.arrow_forward_rounded,
                    color: theme.colorScheme.onSurface.withAlpha(100),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _DayPicker(
                    label: 'To Day',
                    value: _dayEnd,
                    min: _dayStart,
                    max: 28,
                    onChanged: (val) {
                      setState(() => _dayEnd = val);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 36),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: _isSaving ? null : _saveReminder,
                icon: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.save_rounded),
                label: Text(widget.isEditing ? 'Update Reminder' : 'Add Reminder'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
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
          ],
        ),
      ),
    );
  }

  IconData _getCategoryIcon() {
    switch (_category) {
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

  Future<void> _saveReminder() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final now = DateTime.now();
      final amount = double.parse(_amountController.text.trim());

      if (widget.isEditing) {
        final updated = widget.existingReminder!.copyWith(
          title: _titleController.text.trim(),
          amount: amount,
          category: _category,
          dayStart: _dayStart,
          dayEnd: _dayEnd,
          updatedAt: now,
        );
        await widget.firestoreService.updateReminder(updated);
      } else {
        final newReminder = Reminder(
          id: '',
          title: _titleController.text.trim(),
          amount: amount,
          category: _category,
          dayStart: _dayStart,
          dayEnd: _dayEnd,
          isPaidThisCycle: false,
          createdAt: now,
          updatedAt: now,
        );
        await widget.firestoreService.addReminder(newReminder);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.isEditing
                  ? 'Reminder updated successfully'
                  : 'Reminder added successfully',
            ),
            backgroundColor: AppTheme.paidColor,
          ),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppTheme.overdueColor,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}

// Day of the month picker with increment and decrement buttons.
class _DayPicker extends StatelessWidget {
  final String label;
  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;

  const _DayPicker({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      decoration: BoxDecoration(
        color: theme.inputDecorationTheme.fillColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withAlpha(140),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _RoundButton(
                icon: Icons.remove_rounded,
                onTap: value > min ? () => onChanged(value - 1) : null,
              ),
              SizedBox(
                width: 48,
                child: Text(
                  '$value',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              _RoundButton(
                icon: Icons.add_rounded,
                onTap: value < max ? () => onChanged(value + 1) : null,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Circular button for increment or decrement.
class _RoundButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _RoundButton({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEnabled = onTap != null;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: isEnabled
                ? theme.colorScheme.primary.withAlpha(20)
                : theme.colorScheme.onSurface.withAlpha(10),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            size: 18,
            color: isEnabled
                ? theme.colorScheme.primary
                : theme.colorScheme.onSurface.withAlpha(60),
          ),
        ),
      ),
    );
  }
}
