# Customer navigation cleanup

The bottom menu shows Orders only while AppState.loggedIn is true. Guest layouts have Home, Cart, Offers and Account with the original route indices 0, 2, 4, 3. Login/logout rebuilds the existing shell; a guest never mounts the Orders slot. The Orders tap handler also checks the session before and after refreshing order state.

The promotional banner is now informational. The baked-in Ver ofertas button was removed from the artwork, and the banner has no tap callback or button accessibility semantics. Offers remain available from their existing bottom menu destination.

A prominent Continue shopping card replaces the cart's ambiguous plus shortcut and returns through the existing AppNav.home action without clearing items. The empty-cart Explore products action also goes Home (its obsolete index 1 formerly pointed to Orders).

Orders has one leading back arrow, with a Home fallback only when the route cannot pop. The duplicate Home icon was removed from the Orders and tracking app bars; delivery chat remains available. Tracking's existing footer Home action uses an arrow icon.

New project asset: apps/mobile/assets/reference_home/campaign-banner-clean.webp. Created with the built-in image generation edit tool and optimized to WebP. Original generated image: generated_images/exec-c050e80e-459a-4e31-be99-ba51258b5d67.png.
Final prompt:
Use case: precise-object-edit. Edit target: this exact Porto Prime promotional banner. Remove only the small rounded gold button containing 'Ver ofertas' and its right arrow, located on the left below the paragraph and above the three benefit icons. Fill that small area naturally with the existing dark blurred photographic background, continuing the surrounding colors and shadows. Preserve everything else: all existing Portuguese headline and paragraph text, the Porto Prime logo at top left, the beer bottle and glass/ice photography, the three benefit icons and labels, framing, image proportions, all other graphics and colors. Do not introduce any replacement button or new text. This asset will be a decorative, non-clickable banner in an existing mobile app; offers already have their own navigation item.

Local checks: Dart syntax trees, navigation/auth guards, unchanged cart handlers, banner asset and translation-key uniqueness. Flutter SDK is unavailable here, so Flutter widget tests were updated but not executed locally. No API or database changes are required.
