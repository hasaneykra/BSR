import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../config.dart';
import '../models/post.dart';
import '../services/api.dart';
import '../services/store.dart';
import 'article.dart';

/// হোম: ক্যাটাগরি চিপ + অসীম স্ক্রল ফিড।
class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int? _cat;
  List<MapEntry<int, String>> _cats = defaultCategories;

  @override
  void initState() {
    super.initState();
    Api.categories().then((c) {
      if (mounted) setState(() => _cats = c);
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary, borderRadius: BorderRadius.circular(6)),
              child: Text('BSR', style: TextStyle(color: Theme.of(context).colorScheme.onPrimary, fontWeight: FontWeight.w800)),
            ),
            const SizedBox(width: 8),
            const Text('সার্ভিস রুলস', style: TextStyle(fontWeight: FontWeight.w600)),
          ]),
        ),
        body: Column(children: [
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                _chip(t('all'), _cat == null, () => setState(() => _cat = null)),
                for (final c in _cats) _chip(c.value, _cat == c.key, () => setState(() => _cat = c.key)),
              ],
            ),
          ),
          Expanded(child: FeedView(key: ValueKey('f$_cat'), cat: _cat)),
        ]),
      );

  Widget _chip(String label, bool sel, VoidCallback onTap) => Padding(
        padding: const EdgeInsets.only(right: 8, top: 6, bottom: 6),
        child: ChoiceChip(label: Text(label), selected: sel, onSelected: (_) => onTap()),
      );
}

class FeedView extends StatefulWidget {
  final int? cat;
  final String? q;
  const FeedView({super.key, this.cat, this.q});
  @override
  State<FeedView> createState() => _FeedViewState();
}

class _FeedViewState extends State<FeedView> {
  final _sc = ScrollController();
  final List<Post> _items = [];
  int _page = 1, _gen = 0;
  bool _loading = false, _end = false;
  Object? _err;

  @override
  void initState() {
    super.initState();
    _sc.addListener(() {
      if (_sc.position.pixels > _sc.position.maxScrollExtent - 600) _load();
    });
    _load();
  }

  @override
  void didUpdateWidget(FeedView old) {
    super.didUpdateWidget(old);
    if (old.q != widget.q || old.cat != widget.cat) _reset();
  }

  @override
  void dispose() {
    _sc.dispose();
    super.dispose();
  }

  Future<void> _reset() async {
    _gen++;
    setState(() {
      _items.clear();
      _page = 1;
      _end = false;
      _err = null;
      _loading = false;
    });
    await _load();
  }

  Future<void> _load() async {
    if (_loading || _end) return;
    final gen = _gen;
    setState(() {
      _loading = true;
      _err = null;
    });
    try {
      final r = await Api.posts(page: _page, cat: widget.cat, q: widget.q);
      if (!mounted || gen != _gen) return;
      setState(() {
        _items.addAll(r);
        _page++;
        if (r.length < Cfg.perPage) _end = true;
      });
    } catch (e) {
      if (mounted && gen == _gen) setState(() => _err = e);
    } finally {
      if (mounted && gen == _gen) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_items.isEmpty) {
      if (_loading) return const Center(child: CircularProgressIndicator());
      if (_err != null) {
        return Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.cloud_off, size: 48),
            const SizedBox(height: 8),
            Text(t('loadFail')),
            const SizedBox(height: 8),
            FilledButton(onPressed: _reset, child: Text(t('retry'))),
          ]),
        );
      }
      return const SizedBox();
    }
    return RefreshIndicator(
      onRefresh: _reset,
      child: ListView.builder(
        controller: _sc,
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: _items.length + 1,
        itemBuilder: (_, i) {
          if (i == _items.length) {
            if (_err != null) {
              return TextButton(onPressed: _load, child: Text(t('retry')));
            }
            return _end
                ? const SizedBox(height: 24)
                : const Padding(padding: EdgeInsets.all(16), child: Center(child: CircularProgressIndicator(strokeWidth: 2)));
          }
          return PostCard(post: _items[i]);
        },
      ),
    );
  }
}

class PostCard extends StatelessWidget {
  final Post post;
  const PostCard({super.key, required this.post});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      color: cs.surfaceContainerHigh,
      child: InkWell(
        onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => ArticleScreen(post: post))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (post.image.isNotEmpty)
            CachedNetworkImage(
              imageUrl: post.image,
              height: 160,
              width: double.infinity,
              fit: BoxFit.cover,
              fadeInDuration: const Duration(milliseconds: 150),
              placeholder: (_, __) => Container(height: 160, color: cs.surfaceContainerHighest),
              errorWidget: (_, __, ___) => const SizedBox(),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 6, 8),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(post.title, maxLines: 3, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, height: 1.35)),
                  if (post.excerpt.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(post.excerpt, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13)),
                  ],
                  const SizedBox(height: 8),
                  Text(fmtDate(post.date), style: TextStyle(color: cs.primary, fontSize: 12)),
                ]),
              ),
              ListenableBuilder(
                listenable: Store.i,
                builder: (_, __) => IconButton(
                  icon: Icon(Store.i.isSaved(post.id) ? Icons.bookmark : Icons.bookmark_border),
                  onPressed: () => Store.i.toggleSave(post),
                ),
              ),
            ]),
          ),
        ]),
      ),
    );
  }
}
