import 'package:country_picker/country_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../localization/prime_localization.dart';
import '../phone/international_phone.dart';
import '../theme/app_theme.dart';

/// One shared country selector and phone field for customer, courier and partner.
class InternationalPhoneField extends StatelessWidget {
 const InternationalPhoneField({super.key, required this.controller, required this.countryCode,
  required this.onCountryChanged, required this.onChanged, required this.validator,
  this.checking = false, this.available = false});
 final TextEditingController controller;
 final String countryCode;
 final ValueChanged<String> onCountryChanged, onChanged;
 final String? Function(String?) validator;
 final bool checking, available;

 void selectCountry(BuildContext context) {
  FocusScope.of(context).unfocus();
  showCountryPicker(
   context: context, showPhoneCode: true, showSearch: true, showWorldWide: false,
   showDragHandle: true, useSafeArea: true, useRootNavigator: true,
   favorite: const ['BR', 'US', 'ES', 'AR', 'PT', 'GB'],
   header: const Padding(padding: EdgeInsets.fromLTRB(20, 8, 20, 16),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
     PrimeText('Escolha seu país', style: TextStyle(fontSize: 23, fontWeight: FontWeight.w800,
      color: Color(0xFF173E49))),
     SizedBox(height: 6),
     PrimeText('Busque pelo nome ou código do país.', style: TextStyle(fontSize: 13,
      height: 1.4, color: AppColors.muted)),
    ])),
   countryListTheme: CountryListThemeData(
    flagSize: 26, backgroundColor: Colors.white,
    borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
    bottomSheetHeight: MediaQuery.sizeOf(context).height * .86,
    textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF173E49)),
    searchTextStyle: const TextStyle(fontSize: 15, color: Color(0xFF173E49)),
    inputDecoration: PrimeInputDecoration(hintText: 'País ou código, como +55',
     prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF397B87)),
     filled: true, fillColor: const Color(0xFFF0F7F9),
     contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
     border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFD5E5EA))),
     enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFD5E5EA))))),
   onSelect: (country) {
    final raw = controller.text.trim();
    if (raw.startsWith('+')) {
     final parsed = parseInternationalPhone(raw, countryCode);
     if (parsed != null) controller.value = TextEditingValue(text: parsed.formatNsn(),
      selection: TextSelection.collapsed(offset: parsed.formatNsn().length));
    }
    onCountryChanged(country.countryCode);
    onChanged(controller.text);
   },
  );
 }
 void changed(String raw) {
  final parsed = raw.trimLeft().startsWith('+') ? parseInternationalPhone(raw, countryCode) : null;
  if (parsed != null && Country.tryParse(parsed.isoCode.name) != null) {
   final formatted = parsed.formatNsn();
   controller.value = TextEditingValue(text: formatted,
    selection: TextSelection.collapsed(offset: formatted.length));
   onCountryChanged(parsed.isoCode.name);
   onChanged(formatted);
  } else { onChanged(raw); }
 }
 @override Widget build(BuildContext context) {
  final country = Country.tryParse(countryCode) ?? Country.parse('BR');
  final name = country.getTranslatedName(context) ?? country.name;
  return DecoratedBox(decoration: BoxDecoration(color: const Color(0xFFF9FCFD),
   borderRadius: BorderRadius.circular(18), border: Border.all(color: const Color(0xFFD7E6EB), width: 1.2)),
   child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
    Material(color: Colors.transparent, child: InkWell(
     key: const ValueKey('phone-country-selector'), borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
     onTap: () => selectCountry(context),
     child: Padding(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(children: [
       Text(country.flagEmoji, style: const TextStyle(fontSize: 26)),
       const SizedBox(width: 10),
       Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const PrimeText('País / código', style: TextStyle(fontSize: 10.5, height: 1.2, color: AppColors.muted)),
        const SizedBox(height: 4),
        Text(name, maxLines: 1, overflow: TextOverflow.ellipsis,
         style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF173E49))),
       ])),
       const SizedBox(width: 10),
       Text('+' + phoneDialCode(countryCode), style: const TextStyle(fontSize: 15,
        fontWeight: FontWeight.w800, color: Color(0xFF245D6B))),
       const SizedBox(width: 6),
       const Icon(Icons.expand_more_rounded, size: 21, color: Color(0xFF397B87)),
      ])))),
    const Divider(height: 1, indent: 14, endIndent: 14, color: Color(0xFFE0EBEF)),
    TextFormField(
     key: const ValueKey('international-phone-number'),
     controller: controller, keyboardType: TextInputType.phone,
     autofillHints: const [AutofillHints.telephoneNumberNational],
     textInputAction: TextInputAction.next,
     autovalidateMode: AutovalidateMode.onUserInteraction,
     inputFormatters: [
      FilteringTextInputFormatter.allow(RegExp(r'[0-9٠-٩۰-۹０-９+()\s.\-]')),
      LengthLimitingTextInputFormatter(40),
     ],
     onChanged: changed, validator: validator,
     style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF173E49)),
     decoration: PrimeInputDecoration(labelText: 'Celular / WhatsApp', hintText: 'Número com código de área',
      contentPadding: const EdgeInsets.fromLTRB(14, 15, 14, 16), errorMaxLines: 4,
      prefixIcon: const Icon(Icons.phone_outlined, size: 21, color: Color(0xFF397B87)),
      suffixIcon: checking
       ? const Padding(padding: EdgeInsets.all(18), child: SizedBox(width: 17, height: 17,
          child: CircularProgressIndicator(strokeWidth: 2)))
       : available ? const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 21) : null,
      border: const OutlineInputBorder(borderSide: BorderSide.none),
      enabledBorder: const OutlineInputBorder(borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(17),
       borderSide: const BorderSide(color: Color(0xFF77A8B4), width: 1.5))),
    ),
   ]));
 }
}
