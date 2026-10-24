# Category covers and ice weights

Ice uses one inline form, one total and one add action. A weight dropdown includes 3, 6, 10 and 20 kg plus additional weights that actually exist in the selected ice type. Each available weight selects a real product ID; price, remaining stock and cart limits remain unchanged. Missing combinations are disabled. Product names such as "Gelo 3KG" and "Gelo 10KG" now work even without an explicit Cubos/Moído type. No type or price is invented for generic products.

Admin setup: each saleable pack needs its own product with its existing name, price and stock, e.g. "Gelo 3KG", "Gelo 6KG", "Gelo 10KG", "Gelo 20KG", or "Gelo moído 10KG". A generic "Gelo" product stays purchasable but does not acquire fabricated pack sizes.

Every category, including ice, uses the same cover component, height, dark gradient, back control and live title. Admin cover images take priority. The beer category retains its existing photo. Other categories have the bundled neutral coastal photo and their category illustration, or an inset product photo when no 3D illustration exists. Failed or absent remote photos fall back to this bundled cover.

Project asset: apps/mobile/assets/reference_home/category-coast-base.webp (1400x700 WebP). Created with the built-in image generation tool and optimized to WebP for the app. The original generated PNG remains in generated_images/exec-dc010690-e4c9-48f1-b210-d20e1a203b06.png.

Final image prompt:
Use case: precise-object-edit. Asset type: shared photographic background for the Porto Prime category page covers. Edit the attached coastal banner: remove only the beer bottle and beer glass on the right. Seamlessly reconstruct the natural dark coastal rocks and sunset water that would be behind them. Preserve the tropical Bahia coastline, sunset light, palm fronds, camera angle, cinematic natural photography, dark teal negative space across the left half and warm golden light on the right. No products, no people, no text, no logos, no symbols. Keep the wide 2:1 composition. The result will be used as a consistent photo background behind category-specific artwork and live text in a mobile app.

Checks: changed Dart syntax trees, translation-key uniqueness, one ice form/total, real SKU/stock guards, category cover sharing and bundled asset dimensions. Flutter SDK is unavailable in this workspace; Flutter compilation and widget tests were not run locally.
