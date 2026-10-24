import 'package:country_picker/country_picker.dart';
import 'package:phone_numbers_parser/phone_numbers_parser.dart';

IsoCode? phoneIsoCode(String country) {
 for (final code in IsoCode.values) {
  if (code.name == country.toUpperCase()) return code;
 }
 return null;
}

PhoneNumber? parseInternationalPhone(String raw, String country) {
 final value = raw.trim();
 if (value.isEmpty) return null;
 try {
  final iso = phoneIsoCode(country);
  final fallback = Country.tryParse(country);
  if (iso == null && fallback == null) return null;
  final number = iso != null
   ? PhoneNumber.parse(value, callerCountry: iso)
   : PhoneNumber.parse(value.startsWith('+') ? value : '+' + (fallback?.phoneCode ?? '') + value);
  return number.isValid() && RegExp(r'^\+[1-9]\d{1,14}$').hasMatch(number.international) ? number : null;
 } catch (_) { return null; }
}

String phoneDialCode(String country) {
 final iso = phoneIsoCode(country);
 try {
  if (iso != null) return PhoneNumber(isoCode: iso, nsn: '').countryCode;
 } catch (_) { /* Fall back to the country picker's calling-code metadata. */ }
 return Country.tryParse(country)?.phoneCode ?? '';
}
