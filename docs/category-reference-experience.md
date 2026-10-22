# Category reference experience

All category entry points use one shared page with the current category name, icon key, catalogue imagery and products. It does not switch scope when another AppState catalogue category is selected. The hero uses Admin category imagery, a product photo or existing artwork as fallback.

Search, category-specific text facets, stock/offer filters and price/name ordering affect presentation only. Recommended ordering uses existing featuredHome flags and otherwise preserves catalogue order. Facets match the actual name/description/brand text; they do not add inventory classifications or create products.

The product cards preserve AppState.addProduct/changeQty/canIncreaseQuantity. Compare-at discounts and review details appear only when real fields exist; no bestseller counts, ratings or Pix-specific prices are fabricated. The compact cart displays the existing cart subtotal and opens the existing cart/checkout flow.

Existing local favorites remain scoped to each account/device. PT/ES/EN UI labels are included. No API, schema, payment, stock or dispatch rules changed. Dart sources were checked for syntax; full Flutter build and visual checks require the target device.
