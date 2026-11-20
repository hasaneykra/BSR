import 'package:flutter/material.dart';
import '../services/store.dart';
import 'feed.dart';

class ToolsPage extends StatelessWidget {
  const ToolsPage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(t('tools'))),
        body: ListView(padding: const EdgeInsets.all(12), children: [
          _tile(context, Icons.payments_outlined, t('payscale'), t('payscaleSub'),
              () => _push(context, Scaffold(appBar: AppBar(title: Text(t('payscale'))), body: const FeedView(cat: 21)))),
          _tile(context, Icons.savings_outlined, t('gpf'), 'GPF', () => _push(context, const GpfCalc())),
          _tile(context, Icons.elderly_outlined, t('pension'), 'Pension', () => _push(context, const PensionCalc())),
        ]),
      );

  void _push(BuildContext c, Widget w) => Navigator.of(c).push(MaterialPageRoute(builder: (_) => w));

  Widget _tile(BuildContext c, IconData i, String title, String sub, VoidCallback onTap) => Card(
        elevation: 0,
        color: Theme.of(c).colorScheme.surfaceContainerHigh,
        child: ListTile(
          leading: CircleAvatar(backgroundColor: Theme.of(c).colorScheme.primaryContainer, child: Icon(i)),
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
          subtitle: Text(sub),
          trailing: const Icon(Icons.chevron_right),
          onTap: onTap,
        ),
      );
}

double _num(TextEditingController c) => double.tryParse(c.text.trim().replaceAll(',', '')) ?? 0;
String _money(double v) => bnNum(v.round().toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]},'));

Widget _field(TextEditingController c, String label) => Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: c,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
      ),
    );

Widget _result(BuildContext c, List<String> lines) => Card(
      color: Theme.of(c).colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          for (final l in lines) Padding(padding: const EdgeInsets.symmetric(vertical: 3), child: Text(l, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600))),
          const SizedBox(height: 8),
          Text(t('disclaimer'), style: const TextStyle(fontSize: 12)),
        ]),
      ),
    );

/// জিপিএফ: মাসিক জমা + বার্ষিক সুদের হার (ব্যবহারকারী দেন) → আনুমানিক ভবিষ্যৎ জমা।
/// সুদ মাসিক হারে (হার/১২) চক্রবৃদ্ধি ধরা হয়েছে — প্রকৃত হিসাবপদ্ধতির সঙ্গে সামান্য ভিন্ন হতে পারে।
class GpfCalc extends StatefulWidget {
  const GpfCalc({super.key});
  @override
  State<GpfCalc> createState() => _GpfCalcState();
}

class _GpfCalcState extends State<GpfCalc> {
  final open = TextEditingController(text: '0');
  final sub = TextEditingController();
  final rate = TextEditingController();
  final years = TextEditingController();
  List<String>? out;

  void _go() {
    final r = _num(rate) / 100 / 12;
    final n = (_num(years) * 12).round();
    var bal = _num(open);
    final s = _num(sub);
    for (var i = 0; i < n; i++) {
      bal = bal * (1 + r) + s;
    }
    final dep = _num(open) + s * n;
    setState(() => out = ['মোট জমা: ৳ ${_money(dep)}', 'সুদসহ আনুমানিক স্থিতি: ৳ ${_money(bal)}', 'আনুমানিক সুদ: ৳ ${_money(bal - dep)}']);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(t('gpf'))),
        body: ListView(padding: const EdgeInsets.all(16), children: [
          _field(open, 'বর্তমান জমা (৳)'),
          _field(sub, 'মাসিক চাঁদা (৳)'),
          _field(rate, 'বার্ষিক সুদের হার (%) — সর্বশেষ সরকারি আদেশ অনুযায়ী দিন'),
          _field(years, 'কত বছরের হিসাব'),
          FilledButton(onPressed: _go, child: Text(t('calc'))),
          const SizedBox(height: 16),
          if (out != null) _result(context, out!),
        ]),
      );
}

/// পেনশন (আনুমানিক): মাসিক পেনশন = শেষ মূল বেতন × হার% × (চাকরিকাল ÷ পূর্ণ চাকরিকাল)।
/// হার ও পূর্ণ চাকরিকাল সম্পাদনযোগ্য; ডিফল্ট ৫০% ও ২৫ বছর — বিধিমালা যাচাই করে নিন।
class PensionCalc extends StatefulWidget {
  const PensionCalc({super.key});
  @override
  State<PensionCalc> createState() => _PensionCalcState();
}

class _PensionCalcState extends State<PensionCalc> {
  final basic = TextEditingController();
  final years = TextEditingController();
  final pct = TextEditingController(text: '50');
  final full = TextEditingController(text: '25');
  List<String>? out;

  void _go() {
    final f = _num(full) <= 0 ? 25 : _num(full);
    final y = _num(years).clamp(0, f);
    final monthly = _num(basic) * (_num(pct) / 100) * (y / f);
    setState(() => out = ['আনুমানিক মাসিক পেনশন: ৳ ${_money(monthly.toDouble())}', 'বার্ষিক: ৳ ${_money(monthly * 12)}']);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(t('pension'))),
        body: ListView(padding: const EdgeInsets.all(16), children: [
          _field(basic, 'শেষ মূল বেতন (৳)'),
          _field(years, 'যোগ্যতাসূচক চাকরিকাল (বছর)'),
          _field(pct, 'পেনশনের হার (%)'),
          _field(full, 'পূর্ণ পেনশনের জন্য বছর'),
          FilledButton(onPressed: _go, child: Text(t('calc'))),
          const SizedBox(height: 16),
          if (out != null) _result(context, out!),
        ]),
      );
}
