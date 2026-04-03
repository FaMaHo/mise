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
| Login / Join | Sign in or join a household with an invite code |
| Home | Expiring items, shopping list, live "shopping now" indicator |
| Scan / Add | Barcode scanner with manual search fallback |
| Cook suggestions | Full match recipes, then partial matches with missing ingredient nudge |
| Profile | Household members, invite others, notification settings |

---

## Tech stack

- **Flutter** — cross-platform mobile app
- **BLoC** — state management
- **Drift** — local SQLite database, offline-first
- **Firebase** — authentication, real-time sync via Firestore, household invites
- **Spoonacular API** (in research mode - might change) — recipe data and ingredient matching

---

## Getting started

```bash
git clone https://github.com/FaMaHo/mise.git
cd mise
flutter pub get
flutter run
```

> Requires Flutter 3.x, a Firebase project with Auth and Firestore enabled, and a Spoonacular API key. Add your keys to a `.env` file (see `.env.example`).

---

## Other information

Built as a lab project for the Mobile and Embedded Computing course. The app is designed around an offline-first architecture — all data lives locally in Drift and syncs to Firebase when a connection is available. Real-time household updates use Firestore's WebSocket-based listeners.