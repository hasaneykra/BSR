import 'package:flutter/material.dart';
import 'services/push.dart';
import 'services/store.dart';
import 'ui/shell.dart';
import 'ui/theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Store.init();
  runApp(const BsrApp());
  Push.init(); // UI আটকে না রেখে ব্যাকগ্রাউন্ডে চালু হয়
}

class BsrApp extends StatelessWidget {
  const BsrApp({super.key});
  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: Store.i,
        builder: (_, __) => MaterialApp(
          title: 'BSR',
          debugShowCheckedModeBanner: false,
          navigatorKey: navKey,
          scaffoldMessengerKey: messengerKey,
          theme: buildTheme(Brightness.light),
          darkTheme: buildTheme(Brightness.dark),
          themeMode: Store.i.themeMode,
          home: const Shell(),
        ),
      );
}
