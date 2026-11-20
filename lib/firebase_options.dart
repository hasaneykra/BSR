import 'package:firebase_core/firebase_core.dart';

/// Firebase কনফিগ কোডে রাখা হয় না। বিল্ডের সময় --dart-define দিয়ে দিন
/// (README দেখুন)। খালি থাকলে অ্যাপ চলবে, শুধু পুশ নোটিফিকেশন বন্ধ থাকবে।
class DefaultFirebaseOptions {
  static const _apiKey = String.fromEnvironment('FB_API_KEY');
  static const _appId = String.fromEnvironment('FB_APP_ID');
  static const _senderId = String.fromEnvironment('FB_SENDER_ID');
  static const _projectId = String.fromEnvironment('FB_PROJECT_ID');

  static bool get configured =>
      _apiKey.isNotEmpty && _appId.isNotEmpty && _senderId.isNotEmpty && _projectId.isNotEmpty;

  static FirebaseOptions get current => const FirebaseOptions(
        apiKey: _apiKey,
        appId: _appId,
        messagingSenderId: _senderId,
        projectId: _projectId,
      );
}
