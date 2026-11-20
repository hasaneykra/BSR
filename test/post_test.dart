import 'package:flutter_test/flutter_test.dart';
import 'package:bsr/models/post.dart';

void main() {
  test('decodes entities and strips tags', () {
    expect(stripTags('<p>১৯ &#8211; গ্রেড &amp; বেতন</p>'), '১৯ – গ্রেড & বেতন');
  });
  test('Post.fromWp parses minimal json', () {
    final p = Post.fromWp({'id': 5, 'title': {'rendered': 'A'}, 'categories': [21]});
    expect(p.id, 5);
    expect(p.cats, [21]);
  });
}
