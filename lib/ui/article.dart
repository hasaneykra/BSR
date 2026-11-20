import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_html_table/flutter_html_table.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/post.dart';
import '../services/api.dart';
import '../services/store.dart';

class ArticleScreen extends StatefulWidget {
  final Post? post;
  final int? id;
  const ArticleScreen({super.key, this.post, this.id});
  @override
  State<ArticleScreen> createState() => _ArticleScreenState();
}

class _ArticleScreenState extends State<ArticleScreen> {
  Post? _p;
  bool _fail = false;

  @override
  void initState() {
    super.initState();
    _p = widget.post;
    if (_p == null || _p!.content.isEmpty) _fetch();
  }

  Future<void> _fetch() async {
    setState(() => _fail = false);
    try {
      final full = await Api.post(widget.post?.id ?? widget.id!);
      if (mounted) setState(() => _p = full);
    } catch (_) {
      if (mounted) setState(() => _fail = true);
    }
  }

  Future<void> _open(String url) =>
      launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);

  @override
  Widget build(BuildContext context) {
    final p = _p;
    return Scaffold(
      appBar: AppBar(
        actions: [
          if (p != null) ...[
            ListenableBuilder(
              listenable: Store.i,
              builder: (_, __) => IconButton(
                tooltip: t('saved'),
                icon: Icon(Store.i.isSaved(p.id) ? Icons.bookmark : Icons.bookmark_border),
                onPressed: () => Store.i.toggleSave(p),
              ),
            ),
            IconButton(
              tooltip: t('share'),
              icon: const Icon(Icons.share),
              onPressed: () => Share.share('${p.title}\n${p.link}'),
            ),
            PopupMenuButton<String>(
              onSelected: (v) {
                if (v == 'plus') Store.i.setFontScale(Store.i.fontScale + 0.1);
                if (v == 'minus') Store.i.setFontScale(Store.i.fontScale - 0.1);
                if (v == 'web') _open(p.link);
              },
              itemBuilder: (_) => [
                const PopupMenuItem(value: 'plus', child: Text('A+')),
                const PopupMenuItem(value: 'minus', child: Text('A−')),
                PopupMenuItem(value: 'web', child: Text(t('openSite'))),
              ],
            ),
          ],
        ],
      ),
      body: p == null
          ? Center(
              child: _fail
                  ? Column(mainAxisSize: MainAxisSize.min, children: [
                      Text(t('loadFail')),
                      const SizedBox(height: 8),
                      FilledButton(onPressed: _fetch, child: Text(t('retry'))),
                    ])
                  : const CircularProgressIndicator())
          : ListenableBuilder(
              listenable: Store.i,
              builder: (_, __) {
                final s = Store.i.fontScale;
                return ListView(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 40),
                  children: [
                    Text(p.title, style: TextStyle(fontSize: 22 * s, fontWeight: FontWeight.w700, height: 1.35)),
                    const SizedBox(height: 6),
                    Text(fmtDate(p.date), style: TextStyle(color: Theme.of(context).colorScheme.primary)),
                    const SizedBox(height: 12),
                    if (p.content.isEmpty)
                      const Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator()))
                    else
                      Html(
                        data: p.content,
                        extensions: const [TableHtmlExtension()],
                        style: {
                          'body': Style(fontSize: FontSize(17 * s), lineHeight: LineHeight(1.6), margin: Margins.zero, padding: HtmlPaddings.zero),
                        },
                        onLinkTap: (url, _, __) {
                          if (url != null) _open(url);
                        },
                      ),
                  ],
                );
              },
            ),
    );
  }
}
