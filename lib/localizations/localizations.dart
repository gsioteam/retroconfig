

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'en.dart' as en;
import 'zh_hans.dart' as zhHans;
import 'zh_hant.dart' as zhHant;

class LocaleChangedNotification extends Notification {
  Locale locale;
  LocaleChangedNotification(this.locale);
}

class PrettyLocalizations {
  Map words;
  Map total_words;
  PrettyLocalizations(this.words, this.total_words);

  String get(String key) {
    if (words.containsKey(key)) return words[key];
    var txt = total_words[key];
    if (txt == null) txt = key;
    return txt;
  }
}

class PrettyLocalizationsDelegate extends LocalizationsDelegate<PrettyLocalizations> {
  static const Map<String, Locale> supports = const <String, Locale>{
    "en": const Locale.fromSubtags(languageCode: 'en'),
    "zh-hant": const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant'),
    "zh-hans": const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans')
  };

  const PrettyLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<PrettyLocalizations> load(Locale locale) {
    switch (locale.languageCode) {
      case 'zh': {
        if (locale.scriptCode == 'Hans') {
          return get(zhHans.words);
        } else if (locale.scriptCode == 'Hant') {
          return get(zhHant.words);
        } else {
          return get(zhHant.words);
        }
        break;
      }
      default: {
        return get(en.words);
      }
    }
  }

  Future<PrettyLocalizations> get(Map data) {
    return SynchronousFuture<PrettyLocalizations>(PrettyLocalizations(data, data));
  }

  @override
  bool shouldReload(LocalizationsDelegate old) => false;
}

String Function(String) lc(BuildContext ctx) {
  PrettyLocalizations loc = Localizations.of<PrettyLocalizations>(ctx, PrettyLocalizations);
  return (String key)=>loc.get(key);
}

extension PrettyLocalizationsWidget on Widget {
  String kt(BuildContext context, String key) {
    return Localizations.of<PrettyLocalizations>(context, PrettyLocalizations).get(key);
  }
}

extension PrettyLocalizationsState on State {
  String kt(String key) {
    return Localizations.of<PrettyLocalizations>(this.context, PrettyLocalizations).get(key);
  }
}