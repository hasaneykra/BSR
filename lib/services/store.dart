import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/post.dart';
import 'api.dart';

/// অ্যাপের সেটিংস, বুকমার্ক (অফলাইন কপিসহ) ও টপিক সাবস্ক্রিপশন।
class Store extends ChangeNotifier {
  static late SharedPreferences p;
  static final Store i = Store._();
  Store._();

  final List<Post> _saved = [];
  Set<String> topics = {'all'};

  static Future<void> init() async {
    p = await SharedPreferences.getInstance();
    i._saved
      ..clear()
      ..addAll((p.getStringList('saved') ?? []).map((s) {
        try {
          return Post.fromJson(jsonDecode(s) as Map);
        } catch (_) {
          return null;
        }
      }).whereType<Post>());
    final t = p.getStringList('topics');
    i.topics = t == null ? {'all'} : t.toSet();
  }

  // ---- থিম / ভাষা / ফন্ট ----
  ThemeMode get themeMode =>
      const {'light': ThemeMode.light, 'dark': ThemeMode.dark}[p.getString('theme')] ??
      ThemeMode.system;
  void setTheme(String v) {
    p.setString('theme', v);
    notifyListeners();
  }

  String get lang => p.getString('lang') ?? 'bn';
  void setLang(String v) {
    p.setString('lang', v);
    notifyListeners();
  }

  double get fontScale => p.getDouble('font') ?? 1.0;
  void setFontScale(double v) {
    p.setDouble('font', v.clamp(0.8, 1.6));
    notifyListeners();
  }

  // ---- বুকমার্ক ----
  List<Post> get saved => List.unmodifiable(_saved);
  bool isSaved(int id) => _saved.any((e) => e.id == id);

  Future<void> toggleSave(Post post) async {
    if (isSaved(post.id)) {
      _saved.removeWhere((e) => e.id == post.id);
    } else {
      var full = post;
      if (post.content.isEmpty) {
        try {
          full = await Api.post(post.id);
        } catch (_) {}
      }
      _saved.insert(0, full);
    }
    await p.setStringList(
        'saved', _saved.map((e) => jsonEncode(e.toJson())).toList());
    notifyListeners();
  }

  // ---- টপিক ----
  Future<void> setTopicLocal(String t, bool on) async {
    on ? topics.add(t) : topics.remove(t);
    await p.setStringList('topics', topics.toList());
    notifyListeners();
  }

  Future<void> clearCache() async {
    for (final k in p.getKeys().where((k) => k.startsWith('feed_') || k.startsWith('pc_') || k == 'cats')) {
      await p.remove(k);
    }
  }
}

const _t = <String, List<String>>{
  'home': ['হোম', 'Home'],
  'search': ['সার্চ', 'Search'],
  'tools': ['টুলস', 'Tools'],
  'saved': ['সংরক্ষিত', 'Saved'],
  'settings': ['সেটিংস', 'Settings'],
  'all': ['সব', 'All'],
  'searchHint': ['বিধি, আদেশ, পেনশন খুঁজুন…', 'Search rules, orders, pension…'],
  'searchEmpty': ['কিছু লিখে সার্চ করুন', 'Type to search'],
  'retry': ['আবার চেষ্টা করুন', 'Retry'],
  'loadFail': ['লোড করা যায়নি। ইন্টারনেট চেক করুন।', 'Could not load. Check your connection.'],
  'noSaved': ['কোনো সংরক্ষিত পোস্ট নেই। পোস্টে বুকমার্ক দিন, অফলাইনে পড়তে পারবেন।', 'Nothing saved yet. Bookmark posts to read offline.'],
  'offlineBadge': ['অফলাইনে পড়া যাবে', 'Available offline'],
  'theme': ['থিম', 'Theme'],
  'system': ['সিস্টেম', 'System'],
  'light': ['লাইট', 'Light'],
  'dark': ['ডার্ক', 'Dark'],
  'language': ['ভাষা', 'Language'],
  'notif': ['নোটিফিকেশন', 'Notifications'],
  'notifAll': ['সব নতুন পোস্ট', 'All new posts'],
  'notifCat': ['পছন্দের ক্যাটাগরি', 'Favourite categories'],
  'notifOff': ['পুশ নোটিফিকেশন এই বিল্ডে চালু নেই (Firebase কনফিগার করা হয়নি)।', 'Push is not enabled in this build (Firebase not configured).'],
  'clear': ['ক্যাশ মুছুন', 'Clear cache'],
  'cleared': ['ক্যাশ মুছে ফেলা হয়েছে', 'Cache cleared'],
  'openSite': ['ওয়েবসাইট খুলুন', 'Open website'],
  'share': ['শেয়ার', 'Share'],
  'gpf': ['জিপিএফ ক্যালকুলেটর', 'GPF calculator'],
  'pension': ['পেনশন হিসাব (আনুমানিক)', 'Pension estimate'],
  'payscale': ['পে স্কেল ২০২৬', 'Pay scale 2026'],
  'payscaleSub': ['গ্রেডভিত্তিক বেতনের সব পোস্ট', 'All grade-wise salary posts'],
  'calc': ['হিসাব করুন', 'Calculate'],
  'disclaimer': ['এটি আনুমানিক হিসাব। চূড়ান্ত তথ্যের জন্য সরকারি আদেশ/হিসাব দপ্তর দেখুন।', 'Estimate only. Verify with the official order/accounts office.'],
};

String t(String k) {
  final v = _t[k];
  if (v == null) return k;
  return Store.i.lang == 'en' ? v[1] : v[0];
}

String bnNum(String s) {
  if (Store.i.lang == 'en') return s;
  const d = '০১২৩৪৫৬৭৮৯';
  return s.replaceAllMapped(RegExp(r'\d'), (m) => d[int.parse(m[0]!)]);
}

String fmtDate(String iso) {
  final d = DateTime.tryParse(iso);
  if (d == null) return '';
  const bn = ['জানুয়ারি', 'ফেব্রুয়ারি', 'মার্চ', 'এপ্রিল', 'মে', 'জুন', 'জুলাই', 'আগস্ট', 'সেপ্টেম্বর', 'অক্টোবর', 'নভেম্বর', 'ডিসেম্বর'];
  const en = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  final m = (Store.i.lang == 'en' ? en : bn)[d.month - 1];
  return bnNum('${d.day} $m ${d.year}');
}
