import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Presentation-only translations. API values, names and catalogue data stay intact.
class AppLanguage extends ChangeNotifier {
  AppLanguage._();
  static final instance = AppLanguage._();
  static const supported = [Locale('pt', 'BR'), Locale('es', 'ES'), Locale('en', 'US')];
  Locale _locale = supported.first;
  Locale get locale => _locale;
  final Map<String, Map<String, String>> _messages = {};
  final Map<String, List<_Phrase>> _templates = {};
  SharedPreferences? _preferences;

  Future<void> initialize() async {
    _preferences = await SharedPreferences.getInstance();
    for (final code in ['es', 'en']) {
      final raw = jsonDecode(await rootBundle.loadString('assets/localization/$code.json')) as Map<String, dynamic>;
      final messages = raw.map((key, value) => MapEntry(key, value.toString()));
      _messages[code] = messages;
      _templates[code] = messages.entries.where((e) => RegExp(r'\{\d+\}').hasMatch(e.key))
          .where((e) => e.key.replaceAll(RegExp(r'\{\d+\}'), '').trim().length >= 4)
          .map((e) => _Phrase(e.key, e.value)).toList()
        ..sort((a, b) => b.specificity.compareTo(a.specificity));
    }
    final saved = _preferences?.getString('porto-language-v1');
    _locale = supported.firstWhere((l) => l.languageCode == saved, orElse: () => supported.first);
  }

  Future<void> select(String code) async {
    if (!supported.any((l) => l.languageCode == code)) return;
    _locale = supported.firstWhere((l) => l.languageCode == code);
    notifyListeners();
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      await const MethodChannel('porto_prime/language').invokeMethod<void>('setLanguage', {'language': _locale.toLanguageTag()});
    }
    await _preferences?.setString('porto-language-v1', code);
  }

  String translate(String value) {
    final code = locale.languageCode;
    if (code == 'pt' || value.isEmpty) return value;
    final exact = _messages[code]?[value];
    if (exact != null) return exact;
    for (final phrase in _templates[code] ?? <_Phrase>[]) {
      final match = phrase.pattern.firstMatch(value);
      if (match != null) return phrase.render(match);
    }
    return value;
  }
}

class _Phrase {
  _Phrase(this.source, this.target) {
    final tokens = RegExp(r'\{(\d+)\}');
    var cursor = 0;
    final buffer = StringBuffer('^');
    for (final token in tokens.allMatches(source)) {
      buffer.write(RegExp.escape(source.substring(cursor, token.start)));
      buffer.write('([\\s\\S]*?)');
      indices.add(token.group(1)!);
      cursor = token.end;
    }
    buffer.write(RegExp.escape(source.substring(cursor)));
    buffer.write(r'$');
    pattern = RegExp(buffer.toString());
  }
  final String source, target;
  final indices = <String>[];
  late final RegExp pattern;
  int get specificity => source.replaceAll(RegExp(r'\{\d+\}'), '').length;
  String render(RegExpMatch match) => target.replaceAllMapped(RegExp(r'\{(\d+)\}'), (token) {
    final index = indices.indexOf(token.group(1)!);
    return index < 0 ? token.group(0)! : match.group(index + 1)!;
  });
}

T translateLabel<T extends String?>(T text) => (text == null ? null : AppLanguage.instance.translate(text)) as T;

String? Function(String?)? localizeValidator(String? Function(String?)? validator) => validator == null
    ? null : (value) { final error = validator(value); return error == null ? null : AppLanguage.instance.translate(error); };

/// Keeps Flutter's Text layout and accessibility, including const call sites.
class PrimeText extends Text {
  const PrimeText(super.data, {super.key, super.style, super.strutStyle, super.textAlign,
    super.textDirection, super.locale, super.softWrap, super.overflow, super.textScaleFactor,
    super.textScaler, super.maxLines, super.semanticsLabel, super.semanticsIdentifier,
    super.textWidthBasis, super.textHeightBehavior, super.selectionColor});
  @override String? get data => super.data == null ? null : AppLanguage.instance.translate(super.data!);
  @override String? get semanticsLabel => super.semanticsLabel == null ? null : AppLanguage.instance.translate(super.semanticsLabel!);
  @override Widget build(BuildContext context) => ListenableBuilder(
    listenable: AppLanguage.instance, builder: (context, _) => super.build(context));
}

class PrimeInputDecoration extends InputDecoration {
  const PrimeInputDecoration({super.alignLabelWithHint, super.border, super.contentPadding,
    super.counterText, super.enabledBorder, super.errorMaxLines, super.errorText, super.fillColor,
    super.filled, super.focusedBorder, super.helperText, super.hintStyle, super.hintText,
    super.labelText, super.prefixIcon, super.prefixIconConstraints, super.prefixText, super.suffixIcon});
  String? _translate(String? text) => text == null ? null : AppLanguage.instance.translate(text);
  @override String? get labelText => _translate(super.labelText);
  @override String? get hintText => _translate(super.hintText);
  @override String? get helperText => _translate(super.helperText);
  @override String? get errorText => _translate(super.errorText);
  @override String? get counterText => _translate(super.counterText);
}

class LanguagePicker extends StatelessWidget {
  const LanguagePicker({super.key});
  static const labels = {'pt': 'Português', 'es': 'Español', 'en': 'English'};
  static const flags = {'pt': '🇧🇷', 'es': '🇪🇸', 'en': '🇺🇸'};
  @override Widget build(BuildContext context) => ListenableBuilder(
    listenable: AppLanguage.instance,
    builder: (context, _) => PopupMenuButton<String>(
      tooltip: AppLanguage.instance.translate('Idioma'),
      initialValue: AppLanguage.instance.locale.languageCode,
      onSelected: AppLanguage.instance.select,
      position: PopupMenuPosition.under,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      itemBuilder: (context) => labels.entries.map((entry) => PopupMenuItem<String>(
        value: entry.key,
        child: Row(children: [Text(flags[entry.key]!, style: const TextStyle(fontSize: 23)),
          const SizedBox(width: 12), Expanded(child: Text(entry.value)),
          if (entry.key == AppLanguage.instance.locale.languageCode)
            const Icon(Icons.check_rounded, size: 20)]))).toList(),
      child: Container(height: 46, padding: const EdgeInsets.symmetric(horizontal: 9),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFD8E1E3))),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Text(flags[AppLanguage.instance.locale.languageCode]!, style: const TextStyle(fontSize: 22)),
          const Icon(Icons.expand_more_rounded, size: 16)])),
    ));
}
