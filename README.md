# BSR — সরকারি চাকরিজীবীদের অ্যাপ (bdservicerules.com)

Flutter অ্যাপ + নতুন পোস্টে অটো পুশ নোটিফিকেশনের WordPress প্লাগইন।

## ফিচার
- দ্রুত ফিড: হালকা JSON (`_fields`), অসীম স্ক্রল, ছবি ক্যাশ, নেটওয়ার্ক ব্যর্থ হলে ক্যাশ থেকে দেখায়
- ২২+ ক্যাটাগরি ফিল্টার, সার্চ, টেবিলসহ পোস্ট রেন্ডার (পে স্কেল টেবিল)
- বুকমার্ক = অফলাইন কপি; সর্বশেষ ৩০ পড়া পোস্টও অফলাইনে
- টুলস: জিপিএফ ও পেনশন (আনুমানিক) ক্যালকুলেটর, পে স্কেল ২০২৬ পোস্ট
- ডার্ক মোড, বাংলা/ইংরেজি, ফন্ট সাইজ, শেয়ার
- টপিকভিত্তিক পুশ: সব নতুন পোস্ট বা পছন্দের ক্যাটাগরি; নোটিফিকেশনে ট্যাপ করলে সরাসরি পোস্ট খোলে

## ১) Firebase সেটআপ (আপনাকে করতে হবে)
1. console.firebase.google.com → নতুন প্রজেক্ট → Android অ্যাপ যোগ করুন, প্যাকেজ নাম: `com.bdservicerules.bsr`
2. Project settings থেকে চারটি মান নিন: **API key, App ID, Sender ID, Project ID**
3. GitHub রিপো → Settings → Secrets and variables → Actions → এই চারটি Secret যোগ করুন: `FB_API_KEY`, `FB_APP_ID`, `FB_SENDER_ID`, `FB_PROJECT_ID`
4. Project settings → Service accounts → **Generate new private key** (JSON) — এটি রিপোতে রাখবেন না, শুধু ধাপ ২-এর প্লাগইনে দেবেন

## ২) WordPress প্লাগইন
1. `wordpress-plugin/bsr-push` ফোল্ডারটি জিপ করে Plugins → Add New → Upload করুন, চালু করুন
2. Settings → BSR Push → সার্ভিস অ্যাকাউন্ট JSON পেস্ট করে সেভ → "টেস্ট নোটিফিকেশন পাঠান"
3. এরপর থেকে নতুন বা শিডিউল করা পোস্ট পাবলিশ হলেই পুশ যাবে (প্রতি পোস্টে একবার)।
   সার্ভারে WP-Cron বন্ধ থাকলে সার্ভার cron দিয়ে `wp-cron.php` চালান।

## ৩) বিল্ড
- `main`-এ পুশ করলে GitHub Actions → Artifacts → `bsr-apk`
- লোকালি: `./tool/prepare_platform.sh && flutter run --dart-define=FB_API_KEY=... --dart-define=FB_APP_ID=... --dart-define=FB_SENDER_ID=... --dart-define=FB_PROJECT_ID=...`
- Firebase মান না দিলেও অ্যাপ চলে, শুধু পুশ বন্ধ থাকে।
- ডিফল্ট APK ডিবাগ কী দিয়ে সাইন হয় (টেস্টের জন্য)। Play Store-এর জন্য নিজের keystore বানিয়ে সাইনিং যোগ করতে হবে।
- iOS: Apple Developer অ্যাকাউন্ট, APNs কী ও Xcode সাইনিং লাগবে; এই রিপোতে iOS বিল্ড ধাপ নেই।

## জানা সীমাবদ্ধতা
- কোড লেখার সময় Flutter কম্পাইল/টেস্ট চালানো যায়নি; প্রথম CI বিল্ডে ছোট ত্রুটি আসতে পারে।
- ক্যালকুলেটর আনুমানিক; হার ও সূত্র সরকারি আদেশ মিলিয়ে যাচাই করুন।
- অ্যাপ সাইটের পাবলিক WordPress REST API (`/wp-json/wp/v2`) ব্যবহার করে। Wordfence/হাইড-লগইন সেটিংয়ে এটি ব্লক থাকলে ফিড লোড হবে না।
