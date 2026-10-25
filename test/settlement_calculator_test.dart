import 'package:flutter_test/flutter_test.dart';
import 'package:splitpay/features/group_detail/domain/expense.dart';
import 'package:splitpay/features/settlements/data/settlements_provider.dart';

void main() {
  group('SettlementCalculator Greedy Algorithm Tests', () {
    test('Equal split: 3 friends, 1 pays \$300 -> other 2 owe \$100 each', () {
      final members = ['zahid', 'friendA', 'friendB'];
      final expenses = [
        const Expense(
          id: 'e1',
          groupId: 'g1',
          name: 'Munnar Hotel',
          amount: 300,
          memberUid: 'zahid',
        ),
      ];

      final settlements = SettlementCalculator.calculate(
        memberUids: members,
        expenses: expenses,
      );

      expect(settlements.length, 2);
      expect(
        settlements.any(
          (s) =>
              s.debtorUid == 'friendA' &&
              s.creditorUid == 'zahid' &&
              s.amount == 100.0,
        ),
        isTrue,
      );
      expect(
        settlements.any(
          (s) =>
              s.debtorUid == 'friendB' &&
              s.creditorUid == 'zahid' &&
              s.amount == 100.0,
        ),
        isTrue,
      );
    });

    test(
      'Weighted Couple split: Zahid (1x), FriendA (1x), CoupleB (2x) split \$400',
      () {
        final members = ['zahid', 'friendA', 'coupleB'];
        final shares = {
          'zahid': 1,
          'friendA': 1,
          'coupleB': 2,
        }; // 4 total shares
        final expenses = [
          const Expense(
            id: 'e2',
            groupId: 'g1',
            name: 'Houseboat Dinner',
            amount: 400,
            memberUid: 'zahid',
          ),
        ];

        final settlements = SettlementCalculator.calculate(
          memberUids: members,
          expenses: expenses,
          memberShares: shares,
        );

        // Total shares = 4 ($100 per share).
        // CoupleB (2x) must owe $200, and FriendA (1x) must owe $100!
        final coupleSettlement = settlements.firstWhere(
          (s) => s.debtorUid == 'coupleB',
        );
        final singleSettlement = settlements.firstWhere(
          (s) => s.debtorUid == 'friendA',
        );

        expect(coupleSettlement.amount, 200.0);
        expect(singleSettlement.amount, 100.0);
      },
    );
  });
}
