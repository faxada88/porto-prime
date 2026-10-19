# Black and gold mobile identity
Original supplied 1024x1536 artwork is encoded as WebP without cropping. Home uses a single 2:3 image, max width 560, aligned with the Home content margins, followed by the existing catalogue callback. Carousel and its automatic timers are removed.
Shared theme tokens use charcoal, champagne gold, warm ivory and brown; semantic success/error colors remain. Navigation uses white, pale champagne selection and dark gold icons; an opaque safe area covers the gesture inset. Legacy token names and all functional handlers remain.
Updater runs responsive artwork tests, existing reference Home and address tests before building and installing with adb -r.
Flutter runtime validation must run on the developer Windows machine; local checks here cover Dart syntax and asset integrity.
