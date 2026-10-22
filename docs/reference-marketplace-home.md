# Reference Home composition

The customer Home follows the supplied reference at normal phone text scale. The top header intentionally contains no crown or Porto Prime wordmark. Live address selection, notifications, language, category identity, product prices, stock limits and checkout handlers are preserved.

The supplied image is encoded as `assets/reference_home/home-reference-artwork.webp`. `HomeReferenceArtwork` samples only the nine category illustration regions and the horizontal marketing banner. The phone frame, system status bar, navigation, sample prices, product cards and customer address in the screenshot are never rendered as an app screen. These elements are native Flutter widgets backed by the existing AppState. No new marketing artwork was generated.

Home displays up to nine existing categories in rows of four and five; fewer available categories are shown without fabricated entries. All categories remain accessible through search and through Ver todas when more than nine exist. Unknown Admin icon keys use the existing artwork fallback.

The carousel uses Admin-selected products. Favorites are local to each account on this device. The Offers destination uses existing offers categories or genuine compare-at price discounts; it does not fabricate bestseller labels, prices or badges. Existing Home, Orders, Cart and Account indices are unchanged; Offers opens as a normal route.

Spacing scales with available phone width and accessibility text. Product content and text scale may alter card height or line wrapping. Full Flutter rendering must be checked on the target emulator; no Flutter SDK was available in this execution environment.
