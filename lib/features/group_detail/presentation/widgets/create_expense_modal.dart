import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:splitpay/features/group_detail/data/expense_provider.dart';
import 'package:splitpay/shared/widgets/async_elevated_button.dart';
import 'package:splitpay/shared/widgets/splitpay_modal_sheet.dart';

class CreateExpenseModal extends ConsumerStatefulWidget {
  const CreateExpenseModal({super.key, required this.groupId});

  final String groupId;

  @override
  ConsumerState<CreateExpenseModal> createState() => _CreateExpenseModalState();
}

class _CreateExpenseModalState extends ConsumerState<CreateExpenseModal> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final name = _nameController.text.trim();
    final amount = double.tryParse(_amountController.text.trim()) ?? 0;

    await ref
        .read(expenseControllerProvider.notifier)
        .createExpense(groupId: widget.groupId, name: name, amount: amount);

    final state = ref.read(expenseControllerProvider);
    if (!state.hasError && mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final controllerState = ref.watch(expenseControllerProvider);
    final isLoading = controllerState is AsyncLoading;

    return SplitPayModalSheet(
      title: 'Add New Expense',
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Expense Name'),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a name';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Amount',
                prefixText: '\$ ',
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter an amount';
                }
                final parsed = double.tryParse(value.trim());
                if (parsed == null || parsed <= 0) {
                  return 'Please enter a valid positive number';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            AsyncElevatedButton(
              isLoading: isLoading,
              onPressed: _submit,
              child: const Text('Save Expense'),
            ),
          ],
        ),
      ),
    );
  }
}
