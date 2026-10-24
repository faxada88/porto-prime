# International phone registration

Customer, courier and partner registration share one country/calling-code selector and phone field. Brazil is selected initially; the full country_picker 2.0.28 dataset contains 246 countries/territories. Search supports country names, ISO codes and calling codes, including +55. Country names follow Portuguese, Spanish and English. Flags and metadata are bundled with the app, without a lookup service.

phone_numbers_parser 9.0.28 validates national input in its selected country and turns it into E.164 for the availability check and submission. Complete international numbers pasted with + also select their country and become a readable national number. The 11-digit mask is removed. New phoneCountry metadata is stored only in the existing profileData object.

The API uses libphonenumber-js/max 1.13.15. It validates the full international number and retains the country calling code for foreign numbers. Brazilian numbers retain their legacy national storage key so existing accounts and unique constraints remain compatible. Availability and registration both check the legacy national and +55 aliases. Foreign numbers are never compared against a Brazilian key with their + sign removed. No schema, database reset, authentication/session, address, approval, payment or dispatch change is included.

Updater: stop the Nest terminal with Ctrl+C, leave Docker/services running, then run scripts/update-international-phone.ps1 -DeviceId emulator-5554. It installs the locked dependencies, runs targeted checks, builds the API and Android app, restarts the API, waits for database-connected health and installs with adb -r.

Sources: https://pub.dev/packages/country_picker and https://pub.dev/packages/phone_numbers_parser; package source archives inspected. Server parser reference: https://github.com/catamphetamine/libphonenumber-js.

Local checks: TypeScript normalization code exercised with real libphonenumber metadata and all 245 available mobile country examples; Dart syntax and lock/dependency compatibility checked. Flutter SDK and the complete Nest installation are unavailable here, so full builds and Flutter tests are executed by the updater on the user's computer.
