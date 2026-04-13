/// DynamicTranslator
///
/// Provides zero-latency, offline translation of runtime API strings
/// (zone names, disruption types, plan names, nudge text, day names, etc.)
/// for Tamil (ta) and Hindi (hi) locales via a curated lookup dictionary.
///
/// Usage:
///   final t = DynamicTranslator.of(context);
///   Text(t.translate('Heavy Rain'))
library dynamic_translator;

import 'package:flutter/widgets.dart';

class DynamicTranslator {
  final String locale;
  const DynamicTranslator._(this.locale);

  static DynamicTranslator of(BuildContext context) {
    final tag = Localizations.localeOf(context).languageCode;
    return DynamicTranslator._(tag);
  }

  /// Translates a known API string. Returns original if no mapping found.
  String translate(String? input) {
    if (input == null || input.isEmpty) return input ?? '';
    final key = input.trim().toLowerCase();
    final map = locale == 'ta' ? _ta : locale == 'hi' ? _hi : null;
    if (map == null) return input;
    return map[key] ?? _partialMatch(map, key) ?? input;
  }

  /// Tries to find any matching key as a substring for longer API sentences.
  String? _partialMatch(Map<String, String> map, String input) {
    for (final entry in map.entries) {
      if (input.contains(entry.key)) {
        return input.replaceAll(entry.key, entry.value);
      }
    }
    return null;
  }

  // ── Tamil Translations ────────────────────────────────────────────────────

  static const Map<String, String> _ta = {
    // Disruption types
    'heavy rain': 'கனமழை',
    'extreme heat': 'கடுமையான வெப்பம்',
    'platform downtime': 'பிளாட்ஃபார்ம் இடைநிறுத்தம்',
    'cyclone': 'சூறாவளி',
    'flooding': 'வெள்ளம்',
    'disruption': 'இடையூறு',

    // Zone names
    'adyar dark store zone': 'அடையாறு டார்க் ஸ்டோர் மண்டலம்',
    'velachery dark store zone': 'வேளச்சேரி டார்க் ஸ்டோர் மண்டலம்',
    'tambaram dark store zone': 'தாம்பரம் டார்க் ஸ்டோர் மண்டலம்',
    'anna nagar dark store zone': 'அண்ணா நகர் டார்க் ஸ்டோர் மண்டலம்',
    't nagar dark store zone': 'டி நகர் டார்க் ஸ்டோர் மண்டலம்',
    'omr dark store zone': 'ஓஎம்ஆர் டார்க் ஸ்டோர் மண்டலம்',
    'koramangala dark store zone': 'கோரமங்கலா டார்க் ஸ்டோர் மண்டலம்',
    'electronic city dark store zone': 'எலக்ட்ரானிக் சிட்டி டார்க் ஸ்டோர் மண்டலம்',
    'andheri dark store zone': 'அந்தேரி டார்க் ஸ்டோர் மண்டலம்',
    'bandra dark store zone': 'பாந்திரா டார்க் ஸ்டோர் மண்டலம்',

    // Plan names
    'basic shield': 'அடிப்படை கவசம்',
    'standard shield': 'நிலையான கவசம்',
    'full shield': 'முழு கவசம்',
    'basic': 'அடிப்படை',
    'standard': 'நிலையான',
    'full': 'முழு',

    // Day names
    'monday': 'திங்கள்',
    'tuesday': 'செவ்வாய்',
    'wednesday': 'புதன்',
    'thursday': 'வியாழன்',
    'friday': 'வெள்ளி',
    'saturday': 'சனி',
    'sunday': 'ஞாயிறு',

    // Work advisor / nudge phrases
    'earning outlook': 'வருவாய் கண்ணோட்டம்',
    'stable earnings': 'நிலையான வருவாய்',
    'moderate earnings': 'மிதமான வருவாய்',
    'low earnings risk': 'குறைந்த வருவாய் அபாயம்',
    'suggested shift focus': 'பரிந்துரைக்கப்பட்ட ஷிப்ட் கவனம்',
    'morning rush': 'காலை நெரிசல்',
    'evening peak': 'மாலை உச்சம்',
    'lunch hours': 'மதிய நேரம்',
    'night shift': 'இரவு ஷிப்ட்',
    'activate coverage to protect your income during disruptions': 'இடையூறுகளின்போது உங்கள் வருவாயைப் பாதுகாக்க காப்பீட்டை செயல்படுத்தவும்',
    'your coverage is active': 'உங்கள் காப்பீடு செயலில் உள்ளது',
    'heavy rain expected': 'கனமழை எதிர்பார்க்கப்படுகிறது',
    'disruption forecast': 'இடையூறு முன்னறிவிப்பு',
    'risk of heavy rain on': 'கனமழை அபாயம்',
    'will auto-cover any washout shifts': 'எந்த ஷிப்டையும் தானாக காப்பீடு செய்யும்',
    'coverage starts next monday': 'காப்பீடு அடுத்த திங்கட்கிழமை தொடங்கும்',
    'activate quarterly plan now to secure your income': 'உங்கள் வருவாயைப் பாதுகாக்க இப்போதே காலாண்டு திட்டத்தை செயல்படுத்தவும்',
    'plan will auto-cover': 'திட்டம் தானாக காப்பீடு செய்யும்',
  };

  // ── Hindi Translations ────────────────────────────────────────────────────

  static const Map<String, String> _hi = {
    // Disruption types
    'heavy rain': 'भारी बारिश',
    'extreme heat': 'अत्यधिक गर्मी',
    'platform downtime': 'प्लेटफॉर्म डाउनटाइम',
    'cyclone': 'चक्रवात',
    'flooding': 'बाढ़',
    'disruption': 'व्यवधान',

    // Zone names
    'adyar dark store zone': 'अडयार डार्क स्टोर ज़ोन',
    'velachery dark store zone': 'वेलाचेरी डार्क स्टोर ज़ोन',
    'tambaram dark store zone': 'तांबरम डार्क स्टोर ज़ोन',
    'anna nagar dark store zone': 'अन्ना नगर डार्क स्टोर ज़ोन',
    't nagar dark store zone': 'टी नगर डार्क स्टोर ज़ोन',
    'omr dark store zone': 'ओएमआर डार्क स्टोर ज़ोन',
    'koramangala dark store zone': 'कोरमंगला डार्क स्टोर ज़ोन',
    'electronic city dark store zone': 'इलेक्ट्रॉनिक सिटी डार्क स्टोर ज़ोन',
    'andheri dark store zone': 'अंधेरी डार्क स्टोर ज़ोन',
    'bandra dark store zone': 'बांद्रा डार्क स्टोर ज़ोन',

    // Plan names
    'basic shield': 'बेसिक शील्ड',
    'standard shield': 'स्टैंडर्ड शील्ड',
    'full shield': 'फुल शील्ड',
    'basic': 'बेसिक',
    'standard': 'स्टैंडर्ड',
    'full': 'फुल',

    // Day names
    'monday': 'सोमवार',
    'tuesday': 'मंगलवार',
    'wednesday': 'बुधवार',
    'thursday': 'गुरुवार',
    'friday': 'शुक्रवार',
    'saturday': 'शनिवार',
    'sunday': 'रविवार',

    // Work advisor / nudge phrases
    'earning outlook': 'कमाई का आउटलुक',
    'stable earnings': 'स्थिर कमाई',
    'moderate earnings': 'मध्यम कमाई',
    'low earnings risk': 'कम कमाई का जोखिम',
    'suggested shift focus': 'सुझाया गया शिफ्ट फोकस',
    'morning rush': 'सुबह की भीड़',
    'evening peak': 'शाम का पीक',
    'lunch hours': 'दोपहर का समय',
    'night shift': 'रात की शिफ्ट',
    'activate coverage to protect your income during disruptions': 'व्यवधानों के दौरान अपनी कमाई बचाने के लिए कवरेज सक्रिय करें',
    'your coverage is active': 'आपका कवरेज सक्रिय है',
    'heavy rain expected': 'भारी बारिश की संभावना',
    'disruption forecast': 'व्यवधान पूर्वानुमान',
    'risk of heavy rain on': 'भारी बारिश का जोखिम',
    'will auto-cover any washout shifts': 'किसी भी बर्बाद शिफ्ट को स्वचालित रूप से कवर करेगा',
    'coverage starts next monday': 'कवरेज अगले सोमवार से शुरू होगा',
    'activate quarterly plan now to secure your income': 'अपनी कमाई सुरक्षित करने के लिए अभी तिमाही योजना सक्रिय करें',
    'plan will auto-cover': 'योजना स्वचालित रूप से कवर करेगी',
  };
}
