# Home spacing and ice selector

The Home header puts the greeting above a shared address/notification/language row. Notification and language targets are both 48 pixels high; the language picker is compact only on Home. The region stays on its own line.

The product rail uses cards of at least 170 logical pixels, more space when text is enlarged, a separate price line and full-width add/quantity controls. Its timer still pauses for interaction, reduced motion, navigation and app lifecycle. The old cart overlay in category heroes is removed; the cart shortcut after adding items remains.

Ice categories render one inline IceOrderPanel, directly after a compact back/title row. The normal hero, banner, search, filters, sort menu and product grid are bypassed for ice only. Type, pack weight, quantity, one total and one add action are all inside that form; there is no second selection modal in the category flow. Cubos/Moído, 3/6/15/20 kg and additional real weights resolve to existing product IDs and stock. Multiple brands for the same combination share one product dropdown.

In Admin, give each sellable pack its own product, for example "Gelo em cubos 3 kg", "Gelo moído 6 kg" or "Gelo em cubos 20 kg", with its own existing price and stock. Ambiguous or generic names are not used to fabricate variants; they remain purchasable in the same form, under Other options when recognized variants also exist. If all names are generic, the form shows the actual product selection, quantity and total without pretending that weights or ice types are configured. There are no API, database, payment or dispatch changes.

Portuguese, Spanish and English labels are included. Dart syntax and source invariants were checked locally. Flutter compilation and device rendering must be checked on the user's computer because this workspace has no Flutter SDK.
