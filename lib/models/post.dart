String decodeHtml(String s) {
  var o = s.replaceAllMapped(
      RegExp(r'&#(\d+);'), (m) => String.fromCharCode(int.parse(m[1]!)));
  o = o.replaceAllMapped(RegExp(r'&#[xX]([0-9a-fA-F]+);'),
      (m) => String.fromCharCode(int.parse(m[1]!, radix: 16)));
  return o
      .replaceAll('&nbsp;', ' ')
      .replaceAll('&hellip;', '…')
      .replaceAll('&quot;', '"')
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll('&amp;', '&');
}

String stripTags(String s) =>
    decodeHtml(s.replaceAll(RegExp(r'<[^>]*>'), '')).trim();

class Post {
  final int id;
  final String title, excerpt, content, link, date, image;
  final List<int> cats;

  const Post({
    required this.id,
    required this.title,
    this.excerpt = '',
    this.content = '',
    this.link = '',
    this.date = '',
    this.image = '',
    this.cats = const [],
  });

  factory Post.fromWp(Map j) {
    String img = '';
    try {
      final m = (j['_embedded']['wp:featuredmedia'] as List).first as Map;
      final sizes = m['media_details']?['sizes'];
      img = (sizes?['medium_large']?['source_url'] ??
              sizes?['large']?['source_url'] ??
              m['source_url'] ??
              '')
          .toString();
    } catch (_) {}
    return Post(
      id: j['id'] as int,
      title: stripTags((j['title']?['rendered'] ?? '').toString()),
      excerpt: stripTags((j['excerpt']?['rendered'] ?? '').toString()),
      content: (j['content']?['rendered'] ?? '').toString(),
      link: (j['link'] ?? '').toString(),
      date: (j['date'] ?? '').toString(),
      image: img,
      cats: ((j['categories'] ?? []) as List).map((e) => e as int).toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'excerpt': excerpt,
        'content': content,
        'link': link,
        'date': date,
        'image': image,
        'cats': cats,
      };

  factory Post.fromJson(Map j) => Post(
        id: j['id'] as int,
        title: j['title'] as String,
        excerpt: (j['excerpt'] ?? '') as String,
        content: (j['content'] ?? '') as String,
        link: (j['link'] ?? '') as String,
        date: (j['date'] ?? '') as String,
        image: (j['image'] ?? '') as String,
        cats: ((j['cats'] ?? []) as List).map((e) => e as int).toList(),
      );
}
