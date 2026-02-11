# Made: Recipes become Meals

![Flutter](https://img.shields.io/badge/Flutter-02569B?logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-0175C2?logo=dart&logoColor=white)
![Firebase](https://img.shields.io/badge/Firebase-FFCA28?logo=firebase&logoColor=black)
![RevenueCat](https://img.shields.io/badge/RevenueCat-6C63FF?logo=reactivex&logoColor=white)

## About
- A mobile app built for the RevenueCat Shipyard Hackathon, following the creator brief of Eitan Bernath.

- **Problem Statement** People save recipes endlessly but struggle to decide what to cook and rarely follow through.

- **Core Idea:** Made helps users collect recipes from the internet and physical cookbooks, plan meals, and cook with confidence using a low friction flow designed to reduce decision fatigue and increase follow through.

## Links
- [TestFlight Public Link](https://testflight.apple.com/join/zAdEaHde)

## Tech
- Flutter (iOS & Android)
- Dart
- Provider (in-memory app state)
- RevenueCat SDK (subscriptions)
- Firebase Authentication (anonymous + Apple/Google later)
- Firestore Database (recipes, cookbooks, plans, history)
- Firebase Storage (storing images)
- Firebase Cloud Functions (server-side parsing and OCR helpers)
- Google ML Kit (text recognition for cookbook scans)
- Firebase Analytics & Crashlytics – basic tracking & stability

## Architecture

- Mobile: Single Flutter application targeting iOS and Android.
- State: `Provider` drives in-memory app state via a central `Notifier` (`lib/notifiers/notifier.dart`). The `Notifier` holds collections of recipes, cookbooks, planned meals, shopping list items, and user preferences.
- Firestore: user-scoped collections under `/users/{uid}/...` (recipes, cookbooks, cookhistory, plannedmeals, shoppinglist).
- Storage: images uploaded to `users/{uid}/recipe_images/...`.
- Cloud Functions: used for heavy lifting (recipe-from-URL parsing, OCR parsing and ingredient parsing). Functions are deployed in `europe-west2` (see code references).
- Offline / Local: lightweight caching via in-memory state; preferences persisted with `shared_preferences` for small local settings (e.g., unit system).

## Firestore database layout

- `/users/{uid}` document — user metadata
- `/users/{uid}/recipes` — user recipes (recipe documents)
- `/users/{uid}/cookbooks` — user's cookbooks
- `/users/{uid}/plannedmeals` — planning/suggestions
- `/users/{uid}/cookhistory` — cooked events / ratings
- `/users/{uid}/shoppinglist` — shopping list items

## RevenueCat implementation

This app uses RevenueCat to manage subscriptions and gating for the two-tier strategy (Free vs Pro).

- SDKs used: `purchases_flutter` and `purchases_ui_flutter` for paywall presentation and customer info.
- Entitlement key: `RecipeApp Pro` — this entitlement is checked to decide Pro access.

Key behaviors implemented in-app:

- Free plan: users may use the app freely except they are limited to adding up to 3 recipes in lifetime. Deleting recipes does not decrement this counter. The free limit is enforced at UI entry points (e.g., `AddRecipeManuallyPage`) and guarded on save.

- Pro plan: users with an active `RecipeApp Pro` entitlement can add unlimited recipes.

- Checks and paywall flow:
	- The app queries `Purchases.getCustomerInfo()` and inspects `customerInfo.entitlements.active.containsKey('RecipeApp Pro')` to determine entitlement state.
	- When the app detects the free-limit condition (user's `totalRecipesAdded >= 3` and entitlement absent), it presents the RevenueCat paywall to allow the user to subscribe.
	- UI-level guards exist in the add-recipe flow (both page entry and Save actions) so the free limit cannot be bypassed. When blocked, a modal overlay explains the limit and offers an upgrade action which triggers the RevenueCat paywall.

## License

- This project is open source (MIT license) in accordance with the RevenueCat Shipyard Hackathon rules.
