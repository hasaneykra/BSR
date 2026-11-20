import 'package:flutter/material.dart';
import '../services/store.dart';
import 'feed.dart';

class SavedPage extends StatelessWidget {
  const SavedPage({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(t('saved'))),
        body: ListenableBuilder(
          listenable: Store.i,
          builder: (_, __) {
            final l = Store.i.saved;
            if (l.isEmpty) {
              return Center(child: Padding(padding: const EdgeInsets.all(32), child: Text(t('noSaved'), textAlign: TextAlign.center)));
            }
            return ListView.builder(itemCount: l.length, itemBuilder: (_, i) => PostCard(post: l[i]));
          },
        ),
      );
}
