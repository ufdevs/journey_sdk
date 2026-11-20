# JourneySDK for Flutter

Offline-first session & user journey tracking. **All UFDevs apps share one backend** so product analytics stays in one place.

| | |
|--|--|
| **Default backend** | `https://pdfgenai.vercel.app` |
| **Ingest** | `POST /api/journey/batch` |
| **Docs** | [INTEGRATION.md](./INTEGRATION.md) |

---

## Quick start

```yaml
dependencies:
  journey_sdk: ^1.1.0
```

[![pub package](https://img.shields.io/pub/v/journey_sdk.svg)](https://pub.dev/packages/journey_sdk)

```dart
await JourneySDK.init(
  appId: 'my_app',                          // unique per app
  baseUrl: JourneyConfig.defaultBaseUrl,    // https://pdfgenai.vercel.app
  debugLogging: kDebugMode,
);

// MaterialApp
JourneyLifecycleWrapper(
  child: MaterialApp(
    navigatorObservers: [JourneySDK.navigatorObserver],
    ...
  ),
);
```

See **[INTEGRATION.md](./INTEGRATION.md)** for full multi-app setup, tracking APIs, and verification.

---

## Features

- Session-first events with Hive offline queue  
- UTC timestamps + timezone context (correct for India IST and worldwide)  
- Auto screen / lifecycle tracking  
- Helpers: search, AI, ads, taps, notifications, purchases, errors  
- Structured debug logging + flush retries  
- One backend, many `appId`s  

---

## Tracking cheat sheet

```dart
JourneySDK.trackTap(element: 'Generate', elementType: 'button');
JourneySDK.trackSearch(query: 'nda', resultCount: 5);
JourneySDK.trackAiGeneration(model: 'gpt', success: true, latencyMs: 800);
JourneySDK.trackAd(adType: 'rewarded', action: 'impression');
JourneySDK.trackNotification(action: 'opened', notificationId: 'n1');
JourneySDK.trackPurchase(planId: 'pro', amount: 299, currency: 'INR');
JourneySDK.trackError(error: e.toString(), where: 'Pay.checkout');
JourneySDK.identify(userId: id, email: email);
JourneySDK.flush();
```

---

## License

See [LICENSE](./LICENSE).
