import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:team_project/app_drawer.dart';

import 'carddex_api.dart';
import 'collection.dart';

// Palette shared with the login screen.
const _ink = Color(0xFF14213D);
const _teal = Color(0xFF1F7A8C);
const _red = Color(0xFFD62828);
const _cream = Color(0xFFFFF8E1);
const _background = Color(0xFFFFF6CC);

final _api = CardDexApi();

String _money(double v) => '\$${v.toStringAsFixed(2)}';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: _background,
        foregroundColor: _ink,
        elevation: 0,
        title: Text('Home Page', style: TextStyle(fontWeight: FontWeight.w800)),
      ),

      /// Nav Bar
      drawer: const AppDrawer(),
      body: const BrowseView(),
    );
  }
}

class BrowseView extends StatefulWidget {
  const BrowseView({super.key});

  @override
  State<BrowseView> createState() => _BrowseViewState();
}

class _BrowseViewState extends State<BrowseView> {
  late Future<List<CardSet>> _sets;
  late Future<List<CardItem>> _trending;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _sets = _api.getSets().then(_newestFirst);
    _trending = _sets.then(_loadTrending);
  }

  /// Sorts client-side so we don't depend on the API's ordering.
  /// Works for ISO-style dates ("2024-01-31" or "2024/01/31").
  List<CardSet> _newestFirst(List<CardSet> sets) {
    final sorted = [...sets];
    sorted.sort((a, b) => (b.releaseDate ?? '').compareTo(a.releaseDate ?? ''));
    return sorted;
  }

  /// There's no trending endpoint in the CardDex API (as far as the wrapper
  /// shows), so this approximates it: take the two newest sets and show their
  /// most valuable cards. Replace with Firestore "most added" counts later.
  Future<List<CardItem>> _loadTrending(List<CardSet> sets) async {
    final recent = sets.take(2);
    final pages = await Future.wait(
      recent.map((s) => _api.getSetCards(s.id, pageSize: 50)),
    );
    final cards = pages.expand((p) => p).where((c) => c.value != null).toList()
      ..sort((a, b) => b.value!.compareTo(a.value!));
    return cards.take(20).toList();
  }

  Future<void> _refresh() async {
    setState(_load);
    await _sets;
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: 12),
        children: [
          const _SectionHeader('Trending cards'),
          SizedBox(
            height: 230,
            child: _AsyncList<CardItem>(
              future: _trending,
              onRetry: () => setState(_load),
              builder: (card) => _CardTile(
                card: card,
                width: 140,
                onTap: () => _openCard(context, card),
              ),
            ),
          ),
          const SizedBox(height: 16),
          _SectionHeader(
            'Browse by set',
            trailing: TextButton(
              onPressed: () async {
                final sets = await _sets;
                if (!context.mounted) return;
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => AllSetsPage(sets: sets)),
                );
              },
              child: const Text('See all'),
            ),
          ),
          SizedBox(
            height: 100,
            child: _AsyncList<CardSet>(
              future: _sets.then((s) => s.take(20).toList()),
              onRetry: () => setState(_load),
              builder: (set) =>
                  _SetTile(set: set, onTap: () => _openSet(context, set)),
            ),
          ),
        ],
      ),
    );
  }
}

void _openCard(BuildContext context, CardItem card) => Navigator.push(
  context,
  MaterialPageRoute(builder: (_) => CardDetailPage(card: card)),
);

void _openSet(BuildContext context, CardSet set) => Navigator.push(
  context,
  MaterialPageRoute(builder: (_) => SetPage(set: set)),
);

class AllSetsPage extends StatelessWidget {
  final List<CardSet> sets;

  const AllSetsPage({super.key, required this.sets});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('All sets')),
      body: ListView.separated(
        itemCount: sets.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (_, i) => ListTile(
          title: Text(sets[i].name),
          subtitle: sets[i].releaseDate != null
              ? Text(sets[i].releaseDate!)
              : null,
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _openSet(context, sets[i]),
        ),
      ),
    );
  }
}

// ───────────────────────── Set page (paged grid) ─────────────────────────

class SetPage extends StatefulWidget {
  final CardSet set;

  const SetPage({super.key, required this.set});

  @override
  State<SetPage> createState() => _SetPageState();
}

class _SetPageState extends State<SetPage> {
  static const _pageSize = 50;

  final _scroll = ScrollController();
  final List<CardItem> _cards = [];
  int _page = 1;
  bool _loading = false;
  bool _hasMore = true;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      if (_scroll.position.pixels > _scroll.position.maxScrollExtent - 400) {
        _loadMore();
      }
    });
    _loadMore();
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _loadMore() async {
    if (_loading || !_hasMore) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final next = await _api.getSetCards(
        widget.set.id,
        page: _page,
        pageSize: _pageSize,
      );
      setState(() {
        _cards.addAll(next);
        _page++;
        _hasMore = next.length == _pageSize;
      });
    } catch (e) {
      setState(() => _error = e);
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final firstLoad = _cards.isEmpty && _loading;
    final firstError = _cards.isEmpty && _error != null;

    return Scaffold(
      appBar: AppBar(title: Text(widget.set.name)),
      body: firstLoad
          ? const Center(child: CircularProgressIndicator())
          : firstError
          ? Center(
              child: TextButton.icon(
                onPressed: _loadMore,
                icon: const Icon(Icons.refresh),
                label: Text('Could not load cards. Tap to retry\n$_error'),
              ),
            )
          : GridView.builder(
              controller: _scroll,
              padding: const EdgeInsets.all(12),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 0.72,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: _cards.length + (_hasMore ? 1 : 0),
              itemBuilder: (_, i) {
                if (i >= _cards.length) {
                  return Center(
                    child: _error != null
                        ? IconButton(
                            icon: const Icon(Icons.refresh),
                            onPressed: _loadMore,
                          )
                        : const CircularProgressIndicator(strokeWidth: 2),
                  );
                }
                final card = _cards[i];
                return GestureDetector(
                  onTap: () => _openCard(context, card),
                  child: Hero(
                    tag: 'card-${card.id}',
                    child: _CardImage(url: card.imageUrl),
                  ),
                );
              },
            ),
    );
  }
}

class CardDetailPage extends StatelessWidget {
  final CardItem card;

  const CardDetailPage({super.key, required this.card});

  Future<void> _addToCollection(BuildContext context) async {
    // TODO: hook up Firestore here, e.g.
     /*final uid = FirebaseAuth.instance.currentUser!.uid;
     await FirebaseFirestore.instance
         .collection('users').doc(uid)
         .collection('collection').doc(card.id)
         .set({
           'cardId': card.id,
           'quantity': FieldValue.increment(1),
           'addedAt': FieldValue.serverTimestamp(),
         }, SetOptions(merge: true));*/
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${card.name} added to your collection')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: Text(card.name)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 360),
              child: Hero(
                tag: 'card-${card.id}',
                child: InteractiveViewer(child: _CardImage(url: card.largeImageUrl ?? card.imageUrl)),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(card.name, style: textTheme.headlineSmall),
          if (card.value != null) ...[
            const SizedBox(height: 4),
            Text(
              'Market value: ${_money(card.value!)}',
              style: textTheme.bodyMedium,
            ),
          ],
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: () => _addToCollection(context),
            icon: const Icon(Icons.add),
            label: const Text('Add to collection'),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final Widget? trailing;

  const _SectionHeader(this.title, {this.trailing});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
    child: Row(
      children: [
        Expanded(
          child: Text(title, style: Theme.of(context).textTheme.titleLarge),
        ),
        if (trailing != null) trailing!,
      ],
    ),
  );
}

class _AsyncList<T> extends StatelessWidget {
  final Future<List<T>> future;
  final Widget Function(T) builder;
  final VoidCallback onRetry;

  const _AsyncList({
    required this.future,
    required this.builder,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<T>>(
      future: future,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snap.hasError) {
          return Center(
            child: TextButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Failed to load. Tap to retry'),
            ),
          );
        }
        final items = snap.data!;
        if (items.isEmpty) return const Center(child: Text('Nothing here yet'));
        return ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: items.length,
          separatorBuilder: (_, __) => const SizedBox(width: 12),
          itemBuilder: (_, i) => builder(items[i]),
        );
      },
    );
  }
}

class _CardTile extends StatelessWidget {
  final CardItem card;
  final double width;
  final VoidCallback onTap;

  const _CardTile({
    required this.card,
    required this.width,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: width,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Hero(
                tag: 'card-${card.id}',
                child: _CardImage(url: card.imageUrl),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              card.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            if (card.value != null)
              Text(
                _money(card.value!),
                style: Theme.of(context).textTheme.bodySmall,
              ),
          ],
        ),
      ),
    );
  }
}

class _SetTile extends StatelessWidget {
  final CardSet set;
  final VoidCallback onTap;

  const _SetTile({required this.set, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 160,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.colorScheme.secondaryContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              set.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleSmall,
            ),
            if (set.releaseDate != null) ...[
              const SizedBox(height: 4),
              Text(set.releaseDate!, style: theme.textTheme.labelSmall),
            ],
          ],
        ),
      ),
    );
  }
}

class _CardImage extends StatelessWidget {
  final String? url;

  const _CardImage({required this.url});

  @override
  Widget build(BuildContext context) {
    final placeholder = Container(
      color: Colors.black12,
      child: const Center(child: Icon(Icons.image_not_supported)),
    );
    if (url == null) {debugPrint('CardImage: no URL parsed for this card');
    return Container(
      color: Colors.black12,
      child: const Center(child: Icon(Icons.hide_image)),
    );
  }
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
