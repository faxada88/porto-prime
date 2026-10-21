import 'category_labels.dart';
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

  static const Map<String, Map<String, String>> _curated = {
'Produtos que combinam com o seu pedido': {'es': 'Productos que combinan con tu pedido', 'en': 'Great additions to your order'},
'Complete o seu pedido': {'es': 'Completa tu pedido', 'en': 'Complete your order'},
'Buscar produtos': {'es': 'Buscar productos', 'en': 'Search products'},
'Nenhum produto encontrado.': {'es': 'No se encontraron productos.', 'en': 'No products found.'},
'Vale levar junto': {'es': 'Añade algo más', 'en': 'Add a little extra'},
'Continuar apresentação': {'es': 'Reanudar presentación', 'en': 'Resume slideshow'},
'Pausar apresentação': {'es': 'Pausar presentación', 'en': 'Pause slideshow'},
'Produto anterior': {'es': 'Producto anterior', 'en': 'Previous product'},
'Próximo produto': {'es': 'Siguiente producto', 'en': 'Next product'},
"Se o pagamento já estiver em processamento, aguardaremos a confirmação. Somente compras com pagamento confirmado aparecem em Pedidos.": {"es": "Si el pago ya se está procesando, esperaremos la confirmación. Solo las compras con pago confirmado aparecen en Pedidos.", "en": "If your payment is already processing, we will wait for confirmation. Only purchases with confirmed payment appear in Orders."},
"Saldo liberado de checkout não concluído": {"es": "Saldo liberado de una compra no finalizada", "en": "Balance released from an unfinished checkout"},

  'produto': {'es': 'producto', 'en': 'product'},
  'produtos': {'es': 'productos', 'en': 'products'},
  'Ver carrinho': {'es': 'Ver carrito', 'en': 'View cart'},
  'Subtotal': {'es': 'Subtotal', 'en': 'Subtotal'},
  'Subtotal dos produtos': {'es': 'Subtotal de los productos', 'en': 'Product subtotal'},

  "BEM-VINDO(A) AO PORTO PRIME": {
    "es": "TE DAMOS LA BIENVENIDA A PORTO PRIME",
    "en": "WELCOME TO PORTO PRIME"
  },
  "Seu próximo\npedido começa\ncom você.": {
    "es": "Tu próximo\npedido empieza\ncontigo.",
    "en": "Your next\norder starts\nwith you."
  },
  "Crie sua conta para pedir, acompanhar a entrega e usar todos os benefícios do Porto Prime.": {
    "es": "Crea tu cuenta para hacer pedidos, seguir la entrega y disfrutar de todos los beneficios de Porto Prime.",
    "en": "Create your account to order, track your delivery and enjoy all Porto Prime benefits."
  },
  "Seus pedidos": {
    "es": "Tus pedidos",
    "en": "Your orders"
  },
  "Acompanhe tudo em tempo real": {
    "es": "Sigue todo en tiempo real",
    "en": "Track everything in real time"
  },
  "Seus endereços": {
    "es": "Tus direcciones",
    "en": "Your addresses"
  },
  "Gerencie seus endereços": {
    "es": "Gestiona tus direcciones",
    "en": "Manage your addresses"
  },
  "Seu saldo": {
    "es": "Tu saldo",
    "en": "Your balance"
  },
  "Cupons, créditos e benefícios": {
    "es": "Cupones, créditos y beneficios",
    "en": "Coupons, credit and benefits"
  },
  "Criar minha conta": {
    "es": "Crear mi cuenta",
    "en": "Create my account"
  },
  "Entrar na minha conta": {
    "es": "Entrar en mi cuenta",
    "en": "Sign in to my account"
  },
  "Uma conta. Tudo organizado e seguro.": {
    "es": "Una cuenta. Todo organizado y seguro.",
    "en": "One account. Everything organized and secure."
  },
  "ESTAMOS POR PERTO": {
    "es": "ESTAMOS CERCA DE TI",
    "en": "WE’RE HERE FOR YOU"
  },
  "Precisa de ajuda?": {
    "es": "¿Necesitas ayuda?",
    "en": "Need help?"
  },
  "Ajuda e suporte": {
    "es": "Ayuda y soporte",
    "en": "Help and support"
  },
  "Fale com a equipe Porto Prime": {
    "es": "Habla con el equipo de Porto Prime",
    "en": "Talk to the Porto Prime team"
  },
  "Parcerias e patrocínios": {
    "es": "Alianzas y patrocinios",
    "en": "Partnerships and sponsorships"
  },
  "Conte sua ideia para a Porto Prime": {
    "es": "Cuéntale tu idea a Porto Prime",
    "en": "Share your idea with Porto Prime"
  },
  "Privacidade e segurança": {
    "es": "Privacidad y seguridad",
    "en": "Privacy and security"
  },
  "Cuidamos dos seus dados com carinho": {
    "es": "Cuidamos tus datos con atención",
    "en": "We handle your data with care"
  },
  "Muito mais que um destino.": {
    "es": "Mucho más que un destino.",
    "en": "Much more than a destination."
  }
};

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
    final exact = CategoryLabels.translate(value, code) ?? _curated[value]?[code] ?? _messages[code]?[value];
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
