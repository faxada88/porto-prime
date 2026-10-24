import 'package:flutter_test/flutter_test.dart';
import 'package:country_picker/country_picker.dart';
import 'package:porto_prime/core/phone/international_phone.dart';

void main() {
 test('Brazil defaults, local formatting and international paste normalize consistently', () {
  expect(phoneDialCode('BR'), '55');
  expect(parseInternationalPhone('(73) 99999-9999', 'BR')?.international, '+5573999999999');
  expect(parseInternationalPhone('+55 73 99999-9999', 'BR')?.international, '+5573999999999');
 });
 test('National numbers respect their selected country and trunk prefix', () {
  expect(parseInternationalPhone('2025550123', 'US')?.international, '+12025550123');
  expect(parseInternationalPhone('07400 123456', 'GB')?.international, '+447400123456');
  expect(parseInternationalPhone('06 12 34 56 78', 'FR')?.international, '+33612345678');
  expect(parseInternationalPhone('612345678', 'ES')?.international, '+34612345678');
  expect(parseInternationalPhone('+39 06 69821', 'IT')?.international, '+390669821');
 });
 test('The country selector includes the full country dataset and searchable prefixes', () {
  final countries = CountryService().getAll();
  expect(countries.map((c) => c.countryCode).toSet().length, greaterThan(230));
  expect(Country.parse('BR').flagEmoji, '🇧🇷');
  expect(Country.parse('US').phoneCode, '1');
  expect(Country.parse('ES').phoneCode, '34');
  expect(countries.every((c) => c.phoneCode.isNotEmpty && c.flagEmoji.isNotEmpty), isTrue);
 });
 test('Invalid international prefixes and incomplete phone numbers cannot submit', () {
  expect(parseInternationalPhone('+999123456789', 'BR'), isNull);
  expect(parseInternationalPhone('123', 'BR'), isNull);
  expect(parseInternationalPhone('+12025550123123456789', 'US'), isNull);
 });
}
