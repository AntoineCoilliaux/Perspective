# Perspective

**Perspective** is an iOS app that reframes what you spend into something you can actually feel: a price becomes a cost per day, a cost per use, a slice of your working hours, or a comparison to something you buy every week without thinking twice about it.

You bought a €800 phone. Kept it three years. That's €0.73 a day — less than a coffee. Perspective is built around that one moment of "oh, put like that…"

---

## Why

Prices are abstract. €800 doesn't mean much on its own — it's just a number next to a product. But €0.73/day, or "2 hours of your work," or "less than a metro ticket" — those land. Perspective takes anything you own or paid for and reframes it into whichever comparison makes the cost concrete.

## Features

- **Two ways to track a cost**
  - **Per day** — for things you own passively (a laptop, a console, a house). The cost per day drops automatically the longer you keep the item, visualized with a live chart.
  - **Per use** — for things you actively use (running shoes, a gym pass). Log a use with a tap; the cost per use drops with every log.
- **Work-time equivalent** — set your income once in your profile, and every item shows how many minutes or hours of your work it represents.
- **Everyday comparisons** — "less than a coffee," "about the price of a movie ticket." A cost is compared against a small library of everyday reference prices instead of shown as a bare number.
- **Symbolic thresholds** — see how many days remain before an item's cost per day drops below a meaningful milestone (€1, €0.50, etc.), with an optional local notification when it happens.
- **Best value ranking** — Summary highlights your best- and least-amortized items at a glance.
- **Multi-currency** — pick a currency from a flag-based grid; every item remembers the currency it was bought in and converts on the fly for display.
- **Summary dashboard** — total invested over time, cost/day trend, and combined totals across both tracking modes.
- **Fully local** — no account, no backend. Everything lives on-device.

## Tech stack

| Layer | Choice |
|---|---|
| UI | SwiftUI |
| Persistence (items & usage) | SwiftData |
| Persistence (user profile) | `UserDefaults` (Codable struct) |
| State management | `@Observable` view models (iOS 17+) |
| Charts | Swift Charts |
| Notifications | `UserNotifications` (local, threshold-based) |
| Minimum target | iOS 17 |

## Architecture

The app is organized by feature rather than by layer:

```
Perspective/
├── App/                  # App entry point, root TabView
├── Models/               # Item, Usage, UserProfile, Currency, CostReference
├── Features/
│   ├── Profile/          # Income, currency, ProfileViewModel
│   ├── ItemList/         # List, detail, add/edit, ItemListViewModel
│   └── Summary/          # Charts, rankings, SummaryViewModel
├── Shared/
│   ├── Theme.swift       # Colors, typography, reusable card/banner styles
│   └── NotificationManager.swift
└── Resources/
```

A few deliberate choices worth calling out:

- **Cost calculations live on `Item` itself** (as computed properties/extensions), not duplicated across view models. `item.costPerDay`, `item.costPerUse`, `item.daysOwned` are derived purely from the model's own data — no external state needed to compute them.
- **`@Query` stays in views, not view models.** SwiftData's live-updating query property wrapper only works inside a SwiftUI view, so view models expose actions (`delete`, `logUsage`) while views own the query.
- **A single source of truth for currency conversion**, pivoted through EUR, so any currency can convert to any other without an N×N rate table.
- **No premature complexity.** No `Coordinator` pattern, no dependency injection framework — a 3-tab SwiftUI app doesn't need either, and adding them would be complexity for its own sake.


## Known limitations

- Currency conversion rates are fixed and updated manually in code, not fetched live — acceptable for a comparison feature that's already approximate by nature (an item's cost is compared against an approximate reference price, not a real-time market rate).
- Everyday comparison prices (coffee, baguette, movie ticket…) are approximate and denominated in EUR internally.
- No iCloud sync — data is local to the device.

## Possible next steps

- Home screen widget showing an item's current cost per day
- Share sheet export (styled image) for an item's cost breakdown
- Category-based breakdown in Summary
- A "before you buy" simulation mode

## About this project

Built as a solo portfolio project to explore SwiftData, Swift Charts, and SwiftUI's `@Observable` state management on a real (if small) product — end to end, from initial concept through UI design iterations to a working app.
