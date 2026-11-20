import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import '../firebase_options.dart';
import '../ui/article.dart';
import 'store.dart';

final navKey = GlobalKey<NavigatorState>();
final messengerKey = GlobalKey<ScaffoldMessengerState>();

/// FCM টপিক: 'all' = সব নতুন পোস্ট, 'cat_<id>' = নির্দিষ্ট ক্যাটাগরি।
/// WordPress প্লাগইন (bsr-push) একই টপিকে পাঠায়।
class Push {
  static bool ready = false;

  static Future<void> init() async {
    if (!DefaultFirebaseOptions.configured) return;
    try {
      await Firebase.initializeApp(options: DefaultFirebaseOptions.current);
      final m = FirebaseMessaging.instance;
      await m.requestPermission();
      ready = true;
      for (final t in Store.i.topics) {
        await m.subscribeToTopic(t);
      }
      FirebaseMessaging.onMessageOpenedApp.listen(_open);
      final first = await m.getInitialMessage();
      if (first != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _open(first));
      }
      FirebaseMessaging.onMessage.listen((msg) {
        final title = msg.notification?.title ?? 'BSR';
        messengerKey.currentState?.showSnackBar(SnackBar(
          content: Text(title, maxLines: 2, overflow: TextOverflow.ellipsis),
          duration: const Duration(seconds: 8),
          action: SnackBarAction(label: 'খুলুন', onPressed: () => _open(msg)),
        ));
      });
    } catch (_) {
      ready = false;
    }
  }

  static Future<void> setTopic(String topic, bool on) async {
    await Store.i.setTopicLocal(topic, on);
    if (!ready) return;
    final m = FirebaseMessaging.instance;
    on ? await m.subscribeToTopic(topic) : await m.unsubscribeFromTopic(topic);
  }

  static void _open(RemoteMessage msg) {
    final id = int.tryParse('${msg.data['post_id'] ?? ''}');
    if (id == null) return;
    navKey.currentState?.push(MaterialPageRoute(builder: (_) => ArticleScreen(id: id)));
  }
}
