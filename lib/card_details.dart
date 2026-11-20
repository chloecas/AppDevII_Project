import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:team_project/app_drawer.dart';

import 'carddex_api.dart';
import 'collection.dart';
import 'collections_crud.dart';

const _ink = Color(0xFF14213D);
const _teal = Color(0xFF1F7A8C);
const _red = Color(0xFFD62828);
const _cream = Color(0xFFFFF8E1);
const _background = Color(0xFFFFF6CC);

final _api = CardDexApi();

String _money(double? v) => v == null ? '--' : '\$${v.toStringAsFixed(2)}';

class CardDetailPage extends StatefulWidget {
  final CardItem card;

  const CardDetailPage({super.key, required this.card});

  @override
  State<CardDetailPage> createState() => _CardDetailPageState();
}

class _CardDetailPageState extends State<CardDetailPage> {
  late CardItem _card = widget.card;
  bool _loading = true;
  bool _busy = false;

  bool _ownershipLoaded = false;
  bool _owns = false;
  int _qty = 0;
  double? _paid;

  @override
  void initState() {
    super.initState();
    _loadFull();
    _loadOwnership();
    CollectionsCrud.loadBalance();
  }

  Future<void> _loadOwnership() async {
    try {
      final doc = await CollectionsCrud.get(widget.card.id);
      final data = doc.data();
      if (!mounted) return;
      setState(() {
        _owns = doc.exists;
        _qty = (data?['quantity'] as num?)?.toInt() ?? 0;
        _paid = (data?['purchasePrice'] as num?)?.toDouble();
      });
    } catch (e) {
      debugPrint('loadOwnership failed: $e');
    } finally {
      if (mounted) setState(() => _ownershipLoaded = true);
    }
  }

  Future<void> _loadFull() async {
    try {
      final full = await _api.getCard(widget.card.id);
      if (mounted) setState(() => _card = full);
    } catch (e) {
      debugPrint('getCard failed: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  /// Runs a Firestore action, blocks double taps, and reports errors.
  Future<void> _run(
    Future<void> Function() action, {
    String? success,
    required String error,
  }) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
      await _loadOwnership();
      if (success != null) _snack(success);
    } catch (e) {
      debugPrint('$error: $e');
      _snack(e is BalanceException ? e.message : error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _confirmRemoveAll() async {
    final price = _card.value;
    if (price == null) return;

    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sell all?'),
        content: Text(
          'Sell all copies of ${_card.name} for ${_money(price * _qty)}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sell all'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await _run(
            () => CollectionsCrud.sell(_card.id, price, all: true),
        success: 'Sold ${_card.name}',
        error: 'Could not sell the card.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final card = _card;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: _background,
        foregroundColor: _ink,
        elevation: 0,
        title: Text(
          card.name,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 320),
              child: AspectRatio(
                aspectRatio: 0.72,
                child: Hero(
                  tag: 'card-${card.id}',
                  child: InteractiveViewer(
                    child: _DetailImage(
                      url: card.largeImageUrl ?? card.imageUrl,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(card.name, style: textTheme.headlineSmall),
          if (card.value != null) ...[
            const SizedBox(height: 4),
            Text(
              'Market value: ${_money(card.value)}',
              style: textTheme.bodyMedium,
            ),
          ],
          if (_loading) const LinearProgressIndicator(),
          const SizedBox(height: 8),
          Text('HP: ${card.hp ?? '-'}'),
          if (card.rarity != null && card.rarity != 'None')
            Text('Rarity: ${card.rarity}'),
          if (card.abilities.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text('Abilities', style: textTheme.titleMedium),
            for (final ab in card.abilities)
              Text('${ab.name}: ${ab.text ?? ''}'),
          ],
          if (card.attacks.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text('Attacks', style: textTheme.titleMedium),
            for (final a in card.attacks) Text('${a.name}  ${a.damage ?? ''}'),
          ],
          if (card.weaknesses.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              'Weakness: '
              '${card.weaknesses.map((w) => '${w.type} ${w.value}').join(', ')}',
            ),
          ],
          const SizedBox(height: 24),

          ValueListenableBuilder<double?>(
            valueListenable: CollectionsCrud.balance,
            builder: (_, bal, __) => Text(
              'Balance: ${_money(bal)}',
              style: const TextStyle(color: _ink, fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(height: 8),

          // Changes depending on whether the user owns this card.
          if (!_ownershipLoaded)
            const Center(child: CircularProgressIndicator())
          else if (!_owns)
            _addButton()
          else
            _ownedSection(_qty, _paid),
        ],
      ),
    );
  }

  Widget _addButton() {
    final price = _card.value;
    return FilledButton.icon(
      onPressed: (_busy || price == null)
          ? null
          : () => _run(
            () => CollectionsCrud.buy(_card.id, price),
        success: 'Bought ${_card.name}',
        error: 'Could not buy the card.',
      ),
      icon: const Icon(Icons.shopping_cart),
      label: Text(
        price == null ? 'No price available' : 'Buy for ${_money(price)}',
      ),
      style: FilledButton.styleFrom(
        backgroundColor: _ink,
        minimumSize: const Size.fromHeight(48),
      ),
    );
  }

  Widget _ownedSection(int qty, double? paid) {
    final price = _card.value;
    final gain = (price == null || paid == null) ? null : (price - paid) * qty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: _cream,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'In your collection',
                style: TextStyle(
                  color: _ink,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Row(
                children: [
                  IconButton.filledTonal(
                    onPressed: (_busy || price == null)
                        ? null
                        : () => _run(
                          () => CollectionsCrud.sell(_card.id, price),
                      error: 'Could not sell the card.',
                    ),
                    icon: const Icon(Icons.remove),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: Text(
                      '$qty',
                      style: const TextStyle(
                        color: _ink,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  IconButton.filled(
                    onPressed: (_busy || price == null)
                        ? null
                        : () => _run(
                          () => CollectionsCrud.buy(_card.id, price),
                      error: 'Could not buy the card.',
                    ),
                    style: IconButton.styleFrom(backgroundColor: _ink),
                    icon: const Icon(Icons.add),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _infoRow('Total value', _money(price == null ? null : price * qty)),
        _infoRow('Price when added', _money(paid)),
        _infoRow(
          'Gain / loss',
          gain == null
              ? '--'
              : '${gain >= 0 ? '+' : '-'}\$${gain.abs().toStringAsFixed(2)}',
          color: gain == null ? _ink : (gain >= 0 ? _teal : _red),
        ),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: _busy ? null : _confirmRemoveAll,
          icon: const Icon(Icons.delete_outline),
          label: const Text('Sell All'),
          style: OutlinedButton.styleFrom(
            foregroundColor: _red,
            side: const BorderSide(color: _red),
            minimumSize: const Size.fromHeight(48),
          ),
        ),
      ],
    );
  }

  Widget _infoRow(String label, String value, {Color color = _ink}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: _ink, fontSize: 15)),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailImage extends StatelessWidget {
  final String? url;

  const _DetailImage({required this.url});

  @override
  Widget build(BuildContext context) {
    final placeholder = Container(
      color: Colors.black12,
      child: const Center(child: Icon(Icons.image_not_supported)),
    );
    if (url == null) return placeholder;
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.network(
        url!,
        fit: BoxFit.contain,
        loadingBuilder: (context, child, progress) => progress == null
            ? child
            : const Center(child: CircularProgressIndicator(strokeWidth: 2)),
        errorBuilder: (_, __, ___) => placeholder,
      ),
    );
  }
}
