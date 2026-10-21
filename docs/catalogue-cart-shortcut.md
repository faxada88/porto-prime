# Catalogue cart shortcut

Product catalogue pages now expose a floating-style bottom summary once the shared cart contains items. It shows total item quantity, up to two product thumbnails, product names/quantities, the product subtotal and a View cart action. Quantity changes animate; reduced-motion settings disable the animation. It disappears when the cart is empty or the keyboard is open. Layout reserves space below the product list instead of covering product controls.

Only CategoriesPage includes the component. Returning to Home removes the catalogue route and therefore its shortcut; Home keeps the existing menu cart. The shortcut also stays absent from cart and payment pages. Tapping uses AppNav's existing cart tab (index 2), dismisses catalogue routes and retains all current cart, stock, delivery and checkout behavior. The subtotal is AppState.cartSubtotal, not a total including delivery. Cart and locale changes both update the summary.

Category names are localized before interpolation into the catalogue heading and search hint. The shortcut has Portuguese, Spanish and English labels without regenerating interface dictionaries. Product names remain original catalogue data.

Update with scripts/update-tropical-account.ps1, which reuses completed language assets and builds/installs the latest app. Syntax checked with tree-sitter. Flutter build and device rendering were not run in this editing environment.
