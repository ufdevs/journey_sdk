## 1.0.1

* Upgraded dependency constraints to support the latest stable releases (`flutter_bloc ^9.x`, `connectivity_plus ^7.x`, `package_info_plus ^10.x`).
* Built-in obfuscated default endpoint for zero-friction single-line initialization via `JourneySDK.init(appId: '...')`.
* Added optional named parameters to `JourneySDK.init` and overloaded `JourneySDK.initialize`.

## 1.0.0

* Initial stable release of JourneySDK by UFDevs.
* High-performance, offline-first session & user journey tracking for Flutter.
* Hive persistence queue for guaranteed delivery across network disruptions.
* Automated device fingerprinting and persistent anonymous identity.
* Auto-session rotation with configurable timeouts and lifecycle detection.
* BLoC architecture for state management and async event streaming.
* Built-in `JourneyNavigatorObserver` for automatic screen tracking and dwell times.
* Dedicated methods for AI prompts, completions, search, user inputs, and AdMob tracking (`trackAd`).
