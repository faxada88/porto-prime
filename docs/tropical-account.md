# Tropical account welcome

Guest account screen reproduces the reference composition with a coastal photograph, white headline, three translucent benefit cards, yellow create-account action, white sign-in action and a light help panel. The support-24-hours badge is intentionally omitted. Background covers the viewport; content scrolls naturally on short screens and with enlarged text. Existing profile screen for signed-in users is unchanged.

Callbacks remain owned by ProfilePage: `_accountMenu`, `_auth`, `_support`, `_publicSupport(topic: PARTNERSHIP)` and the existing privacy message. No authentication, API, payment, order or registration rules are changed.

New background: `apps/mobile/assets/reference_home/account-coast.webp` (1024×1536, approximately 480 KiB). Generated with the built-in image tool using the supplied account mockup only as a composition reference. Prompt: photographic tropical Porto Seguro coastline, blue ocean to the left, sweeping beach and palms to the right, portrait, sunny, no text, logos or interface controls. It is an illustrative generated coast, not a verified documentary photograph. The geographic signature is rendered as live text. New copy has curated Spanish and English translations.

Updater: `scripts/update-tropical-account.ps1`. If interface language dictionaries have not yet been generated, it delegates to the existing language updater before building the APK; otherwise it uses the dictionaries already present. Docker is needed only for that first language generation. Installation uses ADB `install -r`, preserving app data. Services remain running.

Dart source syntax checked with tree-sitter. Flutter and an Android emulator are unavailable in this editing environment; runtime layout and compilation must be verified on the developer machine.
