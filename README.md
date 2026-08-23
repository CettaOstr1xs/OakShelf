# OakShelf

OakShelf is a premium, beautifully designed book companion and tracker application built using Flutter. It helps book lovers organize their library, track their reading journey, set personal goals, and find inspiration through literature.

---

## Key Features

### 📚 Interactive Library & Shelf Management
- **Organize Your Library:** Categorize books into shelves such as *Currently Reading*, *Want to Read*, and *Completed*.
- **Deep Book Detail View:** Access complete metadata for books, including detailed descriptions, page counts, publisher info, and categories.

### ⏱️ Reading Tracker & Analytics
- **Track Progress:** Stay updated on how many pages you have read and what remains.
- **Personalized Analytics:** Visualize your reading habits and velocity over time.

### 🏆 Reading Challenges
- **Milestone Goals:** Set custom reading challenges (e.g., number of books to read this year).
- **Gamified Achievements:** Unlock milestones and visual achievements as you read more.

### ✍️ Quote Collector & Highlights
- **Daily Inspiration:** Access a curated list of literary quotes directly on your dashboard.
- **Save Your Favorites:** Keep a personal journal of quotes that inspire you, with quick options to save and customize how they are displayed.

### ✨ Premium User Experience
- **Harmonious Visuals:** Hand-crafted color palettes, typography, and clean layout design.
- **Smooth Micro-Animations:** Responsive hover effects, transitions, and gesture-driven animations (powered by `flutter_animate`) that make interactions feel premium and alive.
- **Profile Customization:** Personalize your profile, challenge goals, and application settings.

---

## Tech Stack & Architecture

- **Framework:** Flutter (Dart)
- **State Management & Architecture:** Clean Service-Repository pattern with reactive UI updates.
- **Animations:** Custom animations and transitions using `flutter_animate`.
- **Design System:** Custom theme configurations for consistent layout, typography, and spacing tokens.

---

## Getting Started

To run this project locally, ensure you have the Flutter SDK installed on your machine.

1. **Clone the repository:**
   ```bash
   git clone https://github.com/CettaOstr1xs/bookery.git
   cd bookery
   ```

2. **Get packages:**
   ```bash
   flutter pub get
   ```

3. **Run the app:**
   ```bash
   flutter run
   ```

---

## Library Recovery

OakShelf pins its Firestore storage location to a **Storage ID** (visible in
*Settings*) so anonymous auth session resets can no longer hide your books or
quotes. If a library was stranded under an older account ID, open
**Settings → Library Recovery**, paste the old UID (Firebase Console →
Authentication → Users), and tap **Restore Library**.
