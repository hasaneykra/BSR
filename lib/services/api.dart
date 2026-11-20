import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config.dart';
import '../models/post.dart';
import 'store.dart';

/// নেটওয়ার্ক-ফার্স্ট, ব্যর্থ হলে ক্যাশ। ফিড হালকা (কনটেন্ট ছাড়া), তাই দ্রুত লোড হয়।
class Api {
  static final _c = http.Client();
  static const _timeout = Duration(seconds: 12);

  static Future<List<Post>> posts({int page = 1, int? cat, String? q}) async {
    final qp = <String, String>{
      'per_page': '${Cfg.perPage}',
      'page': '$page',
      '_embed': 'wp:featuredmedia',
      '_fields': 'id,date,link,title,excerpt,categories,_embedded,_links',
      if (cat != null) 'categories': '$cat',
      if (q != null && q.isNotEmpty) 'search': q,
    };
    final cacheKey = (q == null || q.isEmpty) ? 'feed_${cat ?? 0}_$page' : null;
    try {
      final r = await _c.get(Uri.parse('${Cfg.api}/posts').replace(queryParameters: qp)).timeout(_timeout);
      if (r.statusCode == 400) return []; // পেজ শেষ
      if (r.statusCode != 200) throw Exception('HTTP ${r.statusCode}');
      if (cacheKey != null) await Store.p.setString(cacheKey, utf8.decode(r.bodyBytes));
      return _parse(utf8.decode(r.bodyBytes));
    } catch (e) {
      final cached = cacheKey == null ? null : Store.p.getString(cacheKey);
      if (cached != null) return _parse(cached);
      rethrow;
    }
  }

  static List<Post> _parse(String body) =>
      (jsonDecode(body) as List).map((e) => Post.fromWp(e as Map)).toList();

  static Future<Post> post(int id) async {
    final key = 'pc_$id';
    try {
      final r = await _c
          .get(Uri.parse('${Cfg.api}/posts/$id?_embed=wp:featuredmedia'))
          .timeout(_timeout);
      if (r.statusCode != 200) throw Exception('HTTP ${r.statusCode}');
      final body = utf8.decode(r.bodyBytes);
      await _remember(key, body);
      return Post.fromWp(jsonDecode(body) as Map);
    } catch (e) {
      final cached = Store.p.getString(key);
      if (cached != null) return Post.fromWp(jsonDecode(cached) as Map);
      rethrow;
    }
  }

  /// সর্বশেষ ৩০টি পড়া পোস্ট অফলাইনের জন্য ক্যাশে রাখে।
  static Future<void> _remember(String key, String body) async {
    final ids = Store.p.getStringList('pc_ids') ?? [];
    ids.remove(key);
    ids.add(key);
    while (ids.length > 30) {
      await Store.p.remove(ids.removeAt(0));
    }
    await Store.p.setString(key, body);
    await Store.p.setStringList('pc_ids', ids);
  }

  static Future<List<MapEntry<int, String>>> categories() async {
    try {
      final r = await _c
          .get(Uri.parse('${Cfg.api}/categories?per_page=100&hide_empty=true&_fields=id,name,count'))
          .timeout(_timeout);
      if (r.statusCode == 200) {
        final body = utf8.decode(r.bodyBytes);
        await Store.p.setString('cats', body);
        return _cats(body);
      }
    } catch (_) {}
    final c = Store.p.getString('cats');
    return c != null ? _cats(c) : defaultCategories;
  }

  static List<MapEntry<int, String>> _cats(String body) {
    final l = (jsonDecode(body) as List).cast<Map>();
    l.sort((a, b) => (b['count'] as int).compareTo(a['count'] as int));
    return l.map((e) => MapEntry(e['id'] as int, stripTags(e['name'].toString()))).toList();
  }
}
