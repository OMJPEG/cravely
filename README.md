# Cravely (basic version)

A simple Flutter food-delivery demo. Frontend only, mock data, no backend.
All prices, ratings, times and offers are SAMPLE data. Payments are simulated.

Packages: `provider` (state), `shared_preferences` (favourites, profile, onboarding, theme).

## Run in Antigravity (Flutter already installed)

Open a terminal in this folder, then:

```
flutter create . --platforms=android
flutter pub get
flutter run
```

`flutter create .` only adds the missing `android/` folder; it does not touch `lib/`.
Dart comes bundled inside Flutter, so you do not install it separately.

Check your setup any time with `flutter doctor`.

## Build with GitHub (runs on any device)

1. Create a new GitHub repo and push this folder to the `main` branch.
2. Open the repo > Actions > "Build Android APK" (it also runs on every push).
3. When it turns green, open the run and download `cravely-apk` from Artifacts.
4. Unzip, copy `app-release.apk` to any Android phone, install it.

## Demo flow

Home > tap ADD or a dish > Cart > coupon `CRAVE50` (needs subtotal >= 199) > Checkout >
Place order > watch simulated tracking > Orders tab shows it > Reorder.

## Structure

```
lib/main.dart      app + theme + colours (change appName here)
lib/models.dart    Dish, CartItem, Order
lib/data.dart      mock dishes, categories, addresses
lib/state.dart     cart, coupon, favourites, orders (Provider)
lib/screens.dart   all screens and reusable widgets
test/              cart logic tests
```
