# App languages

Portuguese (Brazil) is the default. Home exposes a flag selector beside notifications for Portuguese, Spanish and English. SharedPreferences saves the choice. Flutter's material controls use the same locale. Android also updates the native SDK resource locale without changing the device language.

`update-app-languages.ps1` generates and bundles Spanish and English interface dictionaries using a local LibreTranslate Docker container on localhost:5040, then stops that container and builds/installs the release APK. The app requires no translation server afterwards. Initial model downloads and generation can take several minutes. No automatic product translation or international telephone change is included in this iteration.

`source.json` contains interface phrases and interpolation templates; placeholders are validated during generation. Original state values, dropdown values, API payloads and checkout amounts are untouched. The presentation layer translates known phrases and displays unknown messages in their original language. Customer-written chats, names and catalogue content are not submitted to the translator.

Translations are machine generated, with curated overrides for core navigation. They have not received a native speaker review. New interface strings must be added to source.json and the dictionary generation repeated. Native iOS Stripe screens still follow iOS language settings; this updater targets Android. This environment does not contain Flutter, so release compilation is performed by the updater on the developer computer. No Flutter tests were run here.
