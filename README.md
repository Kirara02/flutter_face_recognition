# 👤 Flutter Face Recognition

A modern, high-fidelity Flutter application for secure **Face Registration and Verification**. This project leverages on-device AI for face detection and embedding extraction, while performing persistent **Face Data Matching on the Backend** for maximum security and scalability.

---

## 💎 Key Features

| Feature                | Detail                                                                                                           |
| ---------------------- | ---------------------------------------------------------------------------------------------------------------- |
| **Clean Architecture** | Feature-First DDD — strict separation of **Data / Domain / Presentation** layers.                                |
| **Face Recognition**   | AI-powered face registration and verification using **Google ML Kit** and **TFLite (MobileFaceNet)**.           |
| **Design System**      | Centralized design tokens for Colors, Spacing, Radius, Shadows, and Typography.                                  |
| **Declarative UI**     | Fluent widget extensions (`.center`, `.padAll`, `.vSpace`) for a cleaner widget tree.                            |
| **State Management**   | Riverpod 3.x with advanced code generation (`riverpod_generator`).                                               |
| **Navigation**         | GoRouter with Nested Shell Routing and type-safe route builders.                                                 |
| **Security**           | `FlutterSecureStorage` for encrypted tokens (Keychain/Keystore).                                                 |
| **Networking**         | Dio with `AuthInterceptor` — seamless refresh token flow & 401 retries.                                          |
| **I18n / L10n**        | Slang — compile-time safe translations with **EN** and **ID** support.                                           |
| **Premium Theming**    | `FlexColorScheme` v8 + Google Fonts, including **System**, **Light**, **Dark**, and **True Black (OLED)** modes. |

---

## 🏗️ Project Architecture

```text
lib/
├── core/
│   ├── auth/                 # SecureStorageService, TokenManager, SessionManager
│   ├── base/                 # UseCase, Result types
│   ├── design_system/        # AppColors, AppSpacing, AppRadius, AppTypography
│   ├── error/                # Custom AppException hierarchy
│   ├── extensions/           # WIDGET, ITERABLE, NUM, CONTEXT extensions
│   ├── gen/                  # Asset/Color generators (flutter_gen)
│   ├── logger/               # Logger configuration
│   ├── network/              # DioClient, AuthInterceptor, safeApiCall
│   ├── response/             # BaseApiResponse, models
│   ├── router/               # GoRouter paths & type-safe Route Builders
│   ├── theme/                # ThemeProvider, FlexColorScheme setup
│   └── utils/                # Mapping and helpers
├── shared/
│   ├── i18n/                 # Slang JSON source (EN/ID) & generated files
│   ├── providers/            # Shared Riverpod providers (SharedPreferences, etc.)
│   └── widgets/              # Standardized UI Components (AppButton, AppTextField, etc.)
└── features/
    ├── auth/
    │   ├── data/             # Datasources, DTOs, Repository implementations
    │   ├── domain/           # Entities, Repository interfaces, Use Cases
    │   └── presentation/     # AuthProvider, AuthController, Screens
    ├── face_recognition/     # AI Modules (ML Kit, TFLite, Custom Camera logic)
    ├── home/
    │   └── presentation/     # HomeScreen and related widgets
    └── settings/
        └── presentation/     # SettingsScreen, MoreScreen, AboutScreen
```

---

## 🛠️ Technical Ecosystem

| Category           | Recommended Libraries                                               |
| ------------------ | ------------------------------------------------------------------- |
| **State**          | `flutter_riverpod` · `riverpod_annotation` · `riverpod_generator`   |
| **AI / ML**        | `google_mlkit_face_detection` · `tflite_flutter`                    |
| **Routing**        | `go_router` · `go_router_builder`                                   |
| **Networking**     | `dio`                                                               |
| **Storage**        | `flutter_secure_storage` · `shared_preferences`                     |
| **Localization**   | `slang` · `slang_flutter`                                           |
| **Theming**        | `flex_color_scheme` · `google_fonts`                                |
| **Persistence**    | `freezed` · `json_serializable`                                     |

---

## 🎭 Face Recognition Implementation

The face recognition module uses a hybrid approach for efficiency and security:

1.  **Face Detection**: Powered by `google_mlkit_face_detection` for high-speed, on-device face tracking.
2.  **Embedding Extraction**: Uses a custom **MobileFaceNet** TFLite model to generate a 192-dimensional vector (embedding) of the detected face.
3.  **Cross-Platform Parity**: Optimized camera streams using `NV21` for Android and `BGRA8888` for iOS to ensure stable frame processing.
4.  **Backend Integration**: Embeddings are sent to a persistent repository (PostgreSQL pgvector) for similarity comparison.

---

## 🏁 Getting Started

### Prerequisites

- Flutter SDK ≥ 3.x (Stable)
- Dart SDK ≥ 3.x

### Installation

1. **Clone the repository**

   ```bash
   git clone https://github.com/Kirara02/flutter_template.git
   cd flutter_template
   ```

2. **Initialize Environment**

   ```bash
   cp .env.example .env   # edit with your BASE_URL
   ```

3. **Install Dependencies**

   ```bash
   flutter pub get
   ```

4. **Run Code Generation**
   We use multiple generators. Run them in this order:

   ```bash
   # 1. Regenerate localization (Slang)
   dart run slang

   # 2. Build Riverpod, Router, and Freezed
   dart run build_runner build --delete-conflicting-outputs
   ```

---

## 🔄 Code Generation Quick Reference

| Task         | Command                                                    |
| ------------ | ---------------------------------------------------------- |
| Refresh All  | `dart run slang && dart run build_runner build -d`         |
| Watch Mode   | `dart run build_runner watch --delete-conflicting-outputs` |
| Build Once   | `dart run build_runner build --delete-conflicting-outputs` |
| Localization | `dart run slang`                                           |

---

## 🌐 Localization (Slang)

Translation source files live in `lib/shared/i18n/`:

```
en.i18n.json   ← English (base)
id.i18n.json   ← Indonesian
```

Usage in Dart:

```dart
// In a widget with BuildContext
context.l10n.login.title
context.l10n.home.greeting(name: user.name)
context.l10n.settings.theme
```

---

## 🌓 Theming & Custom Design System

Access tokens anywhere using `BuildContext`:

```dart
// Access Tokens
context.spacing.md    // 16.0
context.radius.borderMd

// Declarative UI (Extensions)
Text("Hello").center.padAll(AppSpacing.md);

// Spacing Utilities
16.vSpace            // Vertical spacing 16.0
12.hSpace            // Horizontal spacing 12.0
```

---

Built with 💎 by **Kirara Bernstein** (2026).
