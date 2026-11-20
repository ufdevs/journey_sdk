## 1.1.0

* Structured logging via `JourneyLogger` (`[JourneySDK:appId][EVENT|FLUSH|ERROR]`).
* API client retries (configurable `maxRetries`), richer headers (`x-sdk-version`, `x-app-id`, timezone).
* Batch payload includes `sdk` metadata (version, timezone, locale).
* `JourneySDK.init` accepts `baseUrl` directly; documents shared backend `https://pdfgenai.vercel.app`.
* App ID normalization (`photogpt` aliases, lowercase slug).
* New `trackNotification(...)` helper; `pendingEventsCount` getter.
* Warn when `track` is called before `init`.
* Added **INTEGRATION.md** multi-app setup guide.

## 1.0.2

* **Timezone fix:** timestamps serialized as UTC ISO-8601 with `Z`.
* Session `deviceInfo` includes timezone/locale/screen size.
* Lifecycle touch+flush (no premature session kill); `trackTap` / `trackError`.
* Navigator unnamed-route fallback + `navigation_back`.

## 1.0.1

* Dependency constraint upgrades; obfuscated default endpoint; flexible `init`.

## 1.0.0

* Initial stable release.
