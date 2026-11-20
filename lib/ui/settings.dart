import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../config.dart';
import '../services/api.dart';
import '../services/push.dart';
import '../services/store.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});
  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  List<MapEntry<int, String>> _cats = defaultCategories;

  @override
  void initState() {
    super.initState();
    Api.categories().then((c) {
      if (mounted) setState(() => _cats = c);
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = Store.i;
    return Scaffold(
      appBar: AppBar(title: Text(t('settings'))),
      body: ListView(children: [
        _h(t('theme')),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: SegmentedButton<String>(
            segments: [
              ButtonSegment(value: 'system', label: Text(t('system'))),
              ButtonSegment(value: 'light', label: Text(t('light'))),
              ButtonSegment(value: 'dark', label: Text(t('dark'))),
            ],
            selected: {
              switch (s.themeMode) { ThemeMode.light => 'light', ThemeMode.dark => 'dark', _ => 'system' }
            },
            onSelectionChanged: (v) => s.setTheme(v.first),
          ),
        ),
        _h(t('language')),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'bn', label: Text('বাংলা')),
              ButtonSegment(value: 'en', label: Text('English')),
            ],
            selected: {s.lang},
            onSelectionChanged: (v) => s.setLang(v.first),
          ),
        ),
        _h(t('notif')),
        if (!Push.ready)
          Padding(padding: const EdgeInsets.fromLTRB(16, 0, 16, 8), child: Text(t('notifOff'), style: TextStyle(color: Theme.of(context).colorScheme.error))),
        SwitchListTile(
          title: Text(t('notifAll')),
          value: s.topics.contains('all'),
          onChanged: (v) async {
            await Push.setTopic('all', v);
            setState(() {});
          },
        ),
        ExpansionTile(
          title: Text(t('notifCat')),
          children: [
            for (final c in _cats)
              SwitchListTile(
                title: Text(c.value),
                value: s.topics.contains('cat_${c.key}'),
                onChanged: (v) async {
                  await Push.setTopic('cat_${c.key}', v);
                  setState(() {});
                },
              ),
          ],
        ),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.language),
          title: Text(t('openSite')),
          subtitle: const Text('bdservicerules.com'),
          onTap: () => launchUrl(Uri.parse(Cfg.site), mode: LaunchMode.externalApplication),
        ),
        ListTile(
          leading: const Icon(Icons.delete_outline),
          title: Text(t('clear')),
          onTap: () async {
            await s.clearCache();
            if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t('cleared'))));
          },
        ),
        const Padding(padding: EdgeInsets.all(16), child: Text('BSR v1.0.0', textAlign: TextAlign.center)),
      ]),
    );
  }

  Widget _h(String x) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Text(x, style: TextStyle(fontWeight: FontWeight.w700, color: Theme.of(context).colorScheme.primary)),
      );
}
