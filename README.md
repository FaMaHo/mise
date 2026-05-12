# Mise 🍳
### Mahmoudzadeh Fatemeh · Cârjilă Ana Teodora · Mahfood Nour Al Houda

A Flutter app for housemates who want to stop wondering what to cook. Scan items into a shared pantry, and Mise tells you what you can make right now — with what's already home.

---

## What it does

- **Scan to add** — point at a barcode and the item is in your pantry. Manual search if the scan fails.
- **Cook suggestions** — recipes you can make with what you have, ranked. Full matches first, then recipes missing just one or two items with an inline shortcut to add them to the shopping list.
- **Shared household** — join via invite code. Everyone sees the same pantry in real time.
- **Live shopping indicator** — one tap to let your housemates know you're at the store right now.
- **Expiry tracking** — optional expiry dates with alerts before things go bad.
- **Offline first** — works without internet. Syncs when you're back online.

---

## Screens

| Screen | Description |
|---|---|
| Login / Household Setup | Sign in, create or join household via invite code |
| Home | Greeting, pantry overview, expiring items, shopping preview, quick actions |
| Pantry / Full item list, expiry pills, swipe to delete, scan or manual add |
| Shopping List | shared list, check off moves item to pantry, scan to add |
| Cook suggestions | Recipe cards ranked by pantry match, detail sheet with instructions |
| Profile | User's name and email, Household info, invite others|

---

## Tech stack

- **Flutter** — cross-platform mobile
- **BLoC** — state management (PantryBloc, ShoppingBloc, CookBloc)
- **Drift (local SQLite)** — offline-first data layer
- **Firebase Auth** — email/password authentication
- **Cloud Firestore** — real-time sync across devices
- **Spoonacular API** — recipe suggestions by ingredient
- **OpenFoodFacts API** — barcode product lookup


---

## Getting started

```bash
git clone https://github.com/FaMaHo/mise.git
cd mise
flutter pub get
flutter run
```

> Requires Flutter 3.x, a Firebase project with Auth and Firestore enabled, and a Spoonacular API key. Add your keys to a `.env` file (see `.env.example`).