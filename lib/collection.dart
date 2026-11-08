import 'package:flutter/material.dart';
import 'package:team_project/app_drawer.dart';

import 'carddex_api.dart';

// Palette shared with the login screen.
const _ink = Color(0xFF14213D);
const _teal = Color(0xFF1F7A8C);
const _red = Color(0xFFD62828);
const _cream = Color(0xFFFFF8E1);
const _background = Color(0xFFFFF6CC);

final _api = CardDexApi();

/// TODO: the API has no per-user collection. Store the IDs of the cards your
/// user owns (local storage or your own backend), then load them with
/// _api.getCard(id). Until then this shows the newest cards as sample data.
Future<List<CardItem>> fetchCollection() => _api.getCards(pageSize: 24);

String formatValue(double? value) =>
    value == null ? '\$--.--' : '\$${value.toStringAsFixed(2)}';

class CollectionScreen extends StatefulWidget {
  const CollectionScreen({super.key});

  @override
  State<CollectionScreen> createState() => _CollectionScreenState();
}

class _CollectionScreenState extends State<CollectionScreen> {
  late Future<List<CardItem>> _collection = fetchCollection();

  Future<void> _reload() async {
    setState(() => _collection = fetchCollection());
    await _collection;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: _background,
        foregroundColor: _ink,
        elevation: 0,
        title: const Text('My collection',
            style: TextStyle(fontWeight: FontWeight.w800)),
      ),
      drawer: const AppDrawer(),
      body: FutureBuilder<List<CardItem>>(
        future: _collection,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return _MessageView(
              icon: Icons.cloud_off,
              message: 'Could not load your cards.',
              actionLabel: 'Try again',
              onAction: _reload,
            );
          }
          final cards = snapshot.data ?? [];
          if (cards.isEmpty) {
            return _MessageView(
              icon: Icons.style_outlined,
              message: 'No cards yet. Add your first card to start your collection.',
              actionLabel: 'Refresh',
              onAction: _reload,
            );
          }
          final total = cards.every((c) => c.value != null)
              ? cards.fold<double>(0, (sum, c) => sum + c.value!)
              : null;
          return RefreshIndicator(
            onRefresh: _reload,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: _SummaryBar(count: cards.length, total: total),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  sliver: SliverGrid.builder(
                    gridDelegate:
                    const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 200,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      childAspectRatio: 0.58,
                    ),
                    itemCount: cards.length,
                    itemBuilder: (context, i) => _CardTile(card: cards[i]),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SummaryBar extends StatelessWidget {
  const _SummaryBar({required this.count, required this.total});

  final int count;
  final double? total;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: _ink,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _stat('Cards', '$count'),
            _stat('Total value', formatValue(total), alignEnd: true),
          ],
        ),
      ),
    );
  }

  Widget _stat(String label, String value, {bool alignEnd = false}) {
    return Column(
      crossAxisAlignment:
      alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(color: Color(0xFFBFDBF7), fontSize: 12)),
        const SizedBox(height: 2),
        Text(value,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w800)),
      ],
    );
  }
}

class _CardTile extends StatelessWidget {
  const _CardTile({required this.card});

  final CardItem card;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFE066), Color(0xFFF5A623)],
        ),
        boxShadow: const [
          BoxShadow(
              color: Color(0x30000000), blurRadius: 8, offset: Offset(0, 4)),
        ],
      ),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: _cream,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: _CardImage(url: card.imageUrl),
              ),
            ),
            const SizedBox(height: 8),
            Text(card.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    color: _ink, fontSize: 15, fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            Row(
              children: [
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: _teal,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(formatValue(card.value),
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w700)),
                ),
                const Spacer(),
                const Icon(Icons.star, size: 16, color: _red),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Shows the card image, or a colorful placeholder when there is none yet.
class _CardImage extends StatelessWidget {
  const _CardImage({required this.url});

  final String? url;

  @override
  Widget build(BuildContext context) {
    final placeholder = Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF7B2FF7), Color(0xFFF107A3), Color(0xFFFF9F1C)],
        ),
      ),
      child: const Center(
        child: Icon(Icons.auto_awesome, size: 40, color: Colors.white),
      ),
    );
    if (url == null) return placeholder;
    return Image.network(
      url!,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, progress) =>
      progress == null ? child : placeholder,
      errorBuilder: (context, error, stack) => placeholder,
    );
  }
}

class _MessageView extends StatelessWidget {
  const _MessageView({
    required this.icon,
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  final IconData icon;
  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: _ink),
            const SizedBox(height: 12),
            Text(message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: _ink, fontSize: 16)),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: onAction,
              style: FilledButton.styleFrom(backgroundColor: _ink),
              child: Text(actionLabel),
            ),
          ],
        ),
      ),
    );
  }
}