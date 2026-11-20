import 'dart:async';
import 'package:flutter/material.dart';
import '../services/store.dart';
import 'feed.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});
  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final _c = TextEditingController();
  Timer? _d;
  String _q = '';

  @override
  void dispose() {
    _d?.cancel();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: TextField(
            controller: _c,
            decoration: InputDecoration(hintText: t('searchHint'), border: InputBorder.none),
            textInputAction: TextInputAction.search,
            onChanged: (v) {
              _d?.cancel();
              _d = Timer(const Duration(milliseconds: 500), () => setState(() => _q = v.trim()));
            },
          ),
          actions: [
            if (_c.text.isNotEmpty)
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => setState(() {
                  _c.clear();
                  _q = '';
                }),
              ),
          ],
        ),
        body: _q.isEmpty
            ? Center(child: Text(t('searchEmpty')))
            : FeedView(key: ValueKey('s$_q'), q: _q),
      );
}
