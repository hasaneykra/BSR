class Cfg {
  static const site = 'https://bdservicerules.com';
  static const api = '$site/wp-json/wp/v2';
  static const perPage = 15;
}

/// সাইটের ক্যাটাগরি (অফলাইন/প্রথম লোডের জন্য ডিফল্ট তালিকা)।
const defaultCategories = <MapEntry<int, String>>[
  MapEntry(21, 'পে স্কেল ২০২৬'),
  MapEntry(6, 'বেতন স্কেল'),
  MapEntry(13, 'পেনশন'),
  MapEntry(4, 'জিপিএফ'),
  MapEntry(8, 'অফিস আদেশ'),
  MapEntry(16, 'প্রজ্ঞাপন'),
  MapEntry(15, 'বিধিমালা'),
  MapEntry(17, 'নির্দেশিকা'),
  MapEntry(60, 'ছুটি ও সরকারি দিবস'),
  MapEntry(5, 'টাইমস্কেল ও সিলেকশন গ্রেড'),
  MapEntry(10, 'আইবাস রিলেটেড'),
  MapEntry(9, 'ভ্যাট আইটি'),
  MapEntry(7, 'ভ্রমন বিল'),
  MapEntry(18, 'ফরম'),
  MapEntry(57, 'এমপিওভুক্ত শিক্ষক'),
  MapEntry(61, 'শিক্ষা, পরীক্ষা ও নিয়োগ'),
  MapEntry(58, 'নির্বাচনী দায়িত্ব ও ভোটার তথ্য'),
  MapEntry(59, 'নাগরিক ই-সেবা'),
  MapEntry(11, 'নিউজ'),
  MapEntry(19, 'বিজ্ঞপ্তি'),
  MapEntry(14, 'ইসলামিক'),
  MapEntry(12, 'খেলাধুলা'),
  MapEntry(1, 'অন্যান্য'),
];
