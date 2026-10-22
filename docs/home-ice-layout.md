# Home spacing and ice selector

The Home header puts the greeting above a shared address/notification/language row. Notification and language targets are both 48 pixels high; the language picker is compact only on Home. The region stays on its own line.

The product rail uses cards of at least 170 logical pixels, more space when text is enlarged, a separate price line and full-width add/quantity controls. Its timer still pauses for interaction, reduced motion, navigation and app lifecycle. The old cart overlay in category heroes is removed; the cart shortcut after adding items remains.

Ice categories now have a dedicated selector for Cubos and Moído and weights 3, 6, 15 and 20 kg. Other weights actually found in products are included. Every combination resolves to a real product ID, price and stock; unavailable combinations cannot be ordered. Multiple brands with the same type/weight can be selected separately.

In Admin, give each sellable pack its own product, for example "Gelo em cubos 3 kg", "Gelo moído 6 kg" or "Gelo em cubos 20 kg", with its own existing price and stock. Ambiguous or generic names are not used to fabricate variants; those products remain available through the normal category cards. There are no API, database, payment or dispatch changes.

Portuguese, Spanish and English labels are included. Dart syntax and source invariants were checked locally. Flutter compilation and device rendering must be checked on the user's computer because this workspace has no Flutter SDK.
