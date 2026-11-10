# 🚀 JourneySDK for Flutter

High-performance, offline-first session and user journey tracking SDK for Flutter apps. Designed to scale seamlessly across 30+ applications with minimal integration effort and zero server performance bottlenecks.

---

## ✨ Features

- 📱 **Session-First Tracking**: Automatically organizes events into discrete user/device sessions (e.g. 3 app launches = 3 chronological sessions).
- 🆔 **Guaranteed Device Consistency**: Resolves persistent hardware/system device IDs (`device_info_plus` + persistent storage) for guests and authenticated users alike.
- ⚡ **Blazing Fast Local Queue**: Uses **Hive** for sub-millisecond in-memory/disk queueing without dropping events when offline.
- 🧩 **BLoC State Management**: Clean asynchronous event-driven architecture, background batch flushes (every 20 events, 30 seconds, or on app backgrounding).
- 🔍 **Rich Tracking Support**: User searches, text input fields, screen transitions, AI generations, AdMob impressions, in-app purchases, and custom events.
- 📦 **Zero-Friction Reusability**: Single-line initialization for any new app.

---

## 🛠️ Quickstart Installation

### 1. Add dependency in `pubspec.yaml`

```yaml
dependencies:
  journey_sdk:
    path: ../packages/journey_sdk  # Or git repository URL
```

### 2. Initialize in `main.dart`

```dart
import 'package:flutter/material.dart';
import 'package:journey_sdk/journey_sdk.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize JourneySDK with a single line
  await JourneySDK.init(
    appId: 'cvcraft', // Or 'contractly', 'invoice_ai', etc.
    debugLogging: true,
  );

  runApp(const MyApp());
}
```

### 3. Attach Automatic Navigation & Lifecycle Observers

```dart
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return JourneyLifecycleWrapper(
      child: MaterialApp(
        navigatorObservers: [
          JourneySDK.navigatorObserver, // Automatically tracks screen transitions
        ],
        home: const HomeScreen(),
      ),
    );
  }
}
```

---

## 🎯 Usage Examples

### 1. Unified Event Tracking
```dart
JourneySDK.track('template_selected', {
  'templateId': 'nda_v1',
  'category': 'employment',
});
```

### 2. Search & User Input Tracking
```dart
// Track searches
JourneySDK.trackSearch(query: 'freelance contract', resultCount: 10);

// Track inputs & prompts
JourneySDK.trackUserInput(inputField: 'ai_prompt', charCount: 85, maskedValue: 'Draft agreement for...');
```

### 3. AI Generation & AdMob Tracking
```dart
// AI tracking
JourneySDK.trackAiGeneration(
  model: 'gemini-1.5-flash',
  success: true,
  latencyMs: 1200,
  promptLength: 140,
);

// AdMob tracking
JourneySDK.trackAd(adType: 'rewarded', action: 'reward_earned', adUnitId: 'ca-app-pub-xxx/yyy');
```

### 4. User Identity & Authentication
```dart
// Upon login
JourneySDK.identify(
  userId: 'user_123',
  email: 'alex@example.com',
  traits: {'plan': 'pro', 'credits': 50},
);

// Upon logout
JourneySDK.logout();
```
