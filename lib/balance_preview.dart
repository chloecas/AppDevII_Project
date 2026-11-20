import 'package:flutter/material.dart';
import 'collections_crud.dart';

class BalancePreview extends StatefulWidget {
  const BalancePreview({super.key});

  @override
  State<BalancePreview> createState() => _BalanceChipState();
}

class _BalanceChipState extends State<BalancePreview> {
  @override
  void initState() {
    super.initState();
    /// Only fetch if no screen has loaded it yet.
    if (CollectionsCrud.balance.value == null) {
      CollectionsCrud.loadBalance().catchError((e) {
        debugPrint('loadBalance failed: $e');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<double?>(
      valueListenable: CollectionsCrud.balance,
      builder: (_, bal, __) => Padding(
        padding: const EdgeInsets.only(right: 12),
        child: Chip(
          avatar: const Icon(Icons.account_balance_wallet, size: 18),
          label: Text(
            bal == null ? '--' : '\$${bal.toStringAsFixed(2)}',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ),
    );
  }
}