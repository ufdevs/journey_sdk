# JourneySDK — Multi-App Integration Guide

Use this SDK in **any Flutter app** so all activity lands in **one shared backend**.

| Item | Value |
|------|--------|
| **Backend base URL** | `https://pdfgenai.vercel.app` |
| **Ingest endpoint** | `POST /api/journey/batch` |
| **Admin (raw logs)** | `https://pdfgenai.vercel.app/admin/activity` |
| **Analytics UI** | Next.js `analytics_admin` → Python `analytics_service` |
| **SDK version** | `1.1.0` |

Apps are separated only by **`appId`** (e.g. `contractly`, `cvcraft`, `photogpt`, `crowdcast`).  
Do **not** change the base URL per app unless you intentionally want a different environment.

---

## 1. Add the dependency

### Option A — pub.dev (recommended for other apps)

```yaml
# pubspec.yaml
dependencies:
  journey_sdk: ^1.1.0
```

Package page: https://pub.dev/packages/journey_sdk

### Option B — Monorepo path (local development)

```yaml
dependencies:
  journey_sdk:
    path: ../packages/journey_sdk   # adjust relative path
```

### Option C — Git

```yaml
dependencies:
  journey_sdk:
    git:
      url: https://github.com/ufdevs/journey_sdk.git
      ref: main
```

Then:

```bash
flutter pub get
```

---

## 2. Initialize once in `main.dart`

```dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:journey_sdk/journey_sdk.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await JourneySDK.init(
    appId: 'my_new_app', // ← unique slug per app (lowercase)
    // Optional — defaults to https://pdfgenai.vercel.app
    baseUrl: JourneyConfig.defaultBaseUrl,
    debugLogging: kDebugMode, // see [JourneySDK:my_new_app] logs in console
  );

  runApp(const MyApp());
}
```

Or with full config:

```dart
await JourneySDK.init(
  config: JourneyConfig(
    appId: 'my_new_app',
    baseUrl: 'https://pdfgenai.vercel.app',
    debugLogging: kDebugMode,
    batchSize: 20,
    flushInterval: const Duration(seconds: 30),
    sessionTimeout: const Duration(minutes: 30),
    maxRetries: 2,
  ),
);
```

### App ID conventions (keep these stable)

| App | `appId` |
|-----|---------|
| Contractly | `contractly` |
| CVCraft | `cvcraft` |
| PhotoGPT | `photogpt` |
| Crowdcast | `crowdcast` |
| Your next app | `your_slug` (lowercase, no spaces) |

---

## 3. Wire navigation + lifecycle (required for auto screen tracking)

```dart
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return JourneyLifecycleWrapper(
      child: MaterialApp(
        navigatorObservers: [
          JourneySDK.navigatorObserver,
        ],
        // Prefer named routes so screens show up cleanly in analytics
        routes: {
          '/': (_) => const HomeScreen(),
          '/settings': (_) => const SettingsScreen(),
        },
        // Or when pushing:
        // MaterialPageRoute(
        //   settings: const RouteSettings(name: 'SettingsScreen'),
        //   builder: (_) => const SettingsScreen(),
        // )
      ),
    );
  }
}
```

With **go_router**, attach the same observer:

```dart
GoRouter(
  observers: [JourneySDK.navigatorObserver],
  // ...
);
```

---

## 4. Track what matters

```dart
// Screens (also automatic via navigatorObserver if routes are named)
JourneySDK.trackScreen(screenName: 'CheckoutScreen');

// Taps / CTAs
JourneySDK.trackTap(
  element: 'Upgrade to Pro',
  elementType: 'button',
  targetId: 'pro_monthly',
  source: 'paywall',
);

// Search
JourneySDK.trackSearch(query: 'nda', resultCount: 12);

// AI
JourneySDK.trackAiGeneration(
  model: 'gemini-1.5-flash',
  success: true,
  latencyMs: 900,
);

// Ads
JourneySDK.trackAd(
  adType: 'rewarded',
  action: 'reward_earned',
  adUnitId: 'ca-app-pub-xxx/yyy',
);

// Notifications
JourneySDK.trackNotification(
  action: 'opened',
  notificationId: 'campaign_42',
  title: 'Finish your resume',
);

// Purchases
JourneySDK.trackPurchase(
  planId: 'pro_monthly',
  amount: 299,
  currency: 'INR',
  success: true,
);

// Errors
JourneySDK.trackError(
  error: e.toString(),
  where: 'CheckoutScreen.pay',
);

// Custom
JourneySDK.track('feature_used', {'feature': 'export_pdf'}, 'custom');
```

### Identity (login / logout)

```dart
JourneySDK.identify(
  userId: user.id,
  email: user.email,
  traits: {'plan': 'pro'},
);

JourneySDK.logout();
```

### Force sync

```dart
JourneySDK.flush();
```

---

## 5. Verify data is arriving

1. Run the app with `debugLogging: true`.
2. Console should show lines like:
   ```text
   [JourneySDK:my_new_app] Initializing v1.1.0 → https://pdfgenai.vercel.app
   [JourneySDK:my_new_app][EVENT] type=lifecycle name=app_launch ...
   [JourneySDK:my_new_app][FLUSH] OK events=3 http=200
   ```
3. Open admin → **Activity**, filter by your `appId`.
4. Or open Analytics Overview (`analytics_admin`) and select your app.

Quick API smoke test (optional):

```bash
curl -s -X POST https://pdfgenai.vercel.app/api/journey/batch \
  -H 'Content-Type: application/json' \
  -H 'x-app-id: my_new_app' \
  -d '{
    "appId":"my_new_app",
    "deviceId":"test_device_1",
    "session":{"sessionId":"sess_test_1","appId":"my_new_app","deviceId":"test_device_1","startedAt":"2026-11-20T12:00:00.000Z","lastActiveAt":"2026-11-20T12:00:01.000Z","status":"active"},
    "events":[{
      "id":"evt_1","appId":"my_new_app","sessionId":"sess_test_1","seqNo":1,
      "deviceId":"test_device_1","eventType":"lifecycle","eventName":"app_launch",
      "payload":{},"timestamp":"2026-11-20T12:00:00.000Z","source":"journey_sdk"
    }]
  }'
```

---

## 6. What the SDK sends automatically

| Signal | How |
|--------|-----|
| App launch | On `init()` |
| Screen views | `navigatorObserver` + optional `trackScreen` |
| Back navigation | `navigation_back` on pop |
| Foreground / background | `JourneyLifecycleWrapper` |
| UTC timestamps (`…Z`) | Always |
| Timezone / locale | On session `deviceInfo` + every event payload |
| Current screen | Attached to event payloads when known |
| Device id / app version / OS | Session `deviceInfo` |
| Offline queue | Hive — retries on next flush |

---

## 7. Environments

| Environment | `baseUrl` |
|-------------|-----------|
| **Production (shared — use this)** | `https://pdfgenai.vercel.app` |
| Local Node server | `http://10.0.2.2:5000` (Android emulator) or `http://localhost:5000` |

Keep production apps on the shared URL so Contractly / CVCraft / PhotoGPT / new apps all appear in one analytics console.

---

## 8. Checklist for a new app

- [ ] Add `journey_sdk` dependency  
- [ ] `JourneySDK.init(appId: 'your_slug', baseUrl: JourneyConfig.defaultBaseUrl, debugLogging: kDebugMode)`  
- [ ] Wrap root with `JourneyLifecycleWrapper`  
- [ ] Add `JourneySDK.navigatorObserver`  
- [ ] Name routes / `RouteSettings(name: ...)`  
- [ ] `identify` on login, `logout` on sign-out  
- [ ] Track key taps, purchases, ads, notifications, errors  
- [ ] Confirm FLUSH OK in logs and events in `/admin/activity`  
