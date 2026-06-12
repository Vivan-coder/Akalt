# Akalt 🌶️

Akalt is a premium, video-first food discovery platform designed for the Bahraini market. It reimagines traditional text-heavy menus as an immersive, TikTok-style vertical video feed, allowing users to discover signature dishes from local restaurants and order or save them seamlessly.

The application features a sleek, minimalist aesthetic built around a **Solid Black** backdrop and high-contrast **Apple Red** interactive elements.

---

## 🚀 Tech Stack & Architecture

- **Frontend Framework:** Flutter `3.35.7` (Stable)
- **Language:** Dart `3.9.2`
- **State Management:** Riverpod (AsyncNotifier & StreamProviders)
- **Backend Services:** Firebase Suite
  - **Authentication:** Firebase Auth
  - **Database:** Cloud Firestore (Optimized for `feedScore` ranking)
  - **Storage:** Firebase Cloud Storage (`akalt-27d06.firebasestorage.app`)
- **Video Playback:** Native `video_player` implementation with lifecycle handling.

---

## 🛠️ Project Structure

```text
lib/
├── main.dart                 # App initialization & App Check guardrails
├── models/                   # Immutable data representations (VideoModel, UserModel)
├── services/                 # Firebase API layer (AuthService, VideoService)
└── screens/                  # Feature-based UI architecture
    ├── auth/                 # Login, Verification, and Landing interfaces
    ├── feed/                 # TikTok-style vertical scrolling feed & video overlay
    └── upload/               # Media selection and Cloud Storage ingestion
