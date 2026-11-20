library journey_sdk;

import 'src/api/journey_api_client.dart';
import 'src/bloc/journey_bloc.dart';
import 'src/bloc/journey_event.dart';
import 'src/config/journey_config.dart';
import 'src/core/device_identifier.dart';
import 'src/core/journey_logger.dart';
import 'src/core/session_manager.dart';
import 'src/observers/journey_navigator_observer.dart';
import 'src/storage/hive_event_queue.dart';

export 'src/config/journey_config.dart';
export 'src/models/session_record.dart';
export 'src/models/tracked_event.dart';
export 'src/observers/journey_navigator_observer.dart';
export 'src/widgets/journey_lifecycle_wrapper.dart';

////// The single unified static facade for JourneySDK
class JourneySDK {
  static JourneyConfig? _config;
  static JourneyBloc? _bloc;
  static String? _deviceId;
  static final JourneyNavigatorObserver _navigatorObserver =
      JourneyNavigatorObserver();

  /// NavigatorObserver instance for automatic screen route tracking in MaterialApp
  static JourneyNavigatorObserver get navigatorObserver => _navigatorObserver;

  /// Active JourneySDK configuration
  static JourneyConfig? get config => _config;

  /// Current persistent device ID
  static String? get deviceId => _deviceId;

  /// Current active session ID
  static String? get currentSessionId => _bloc?.state.currentSession?.sessionId;

  /// Is the SDK initialized
  static bool get isInitialized => _bloc != null;

  /// Initialize the JourneySDK for this Flutter application.
  ///
  /// All apps should use the **same** [baseUrl] (default:
  /// [JourneyConfig.defaultBaseUrl] = `https://pdfgenai.vercel.app`) so
  /// events land in one Mongo analytics store, separated by [appId].
  static Future<void> init({
    JourneyConfig? config,
    String? appId,
    String? baseUrl,
    bool debugLogging = false,
  }) async {
    if (isInitialized) {
      JourneyLogger.w('init() called again — ignored (already initialized)');
      return;
    }
    final effectiveConfig = config ??
        JourneyConfig(
          appId: appId ?? 'app',
          baseUrl: baseUrl,
          debugLogging: debugLogging,
        );
    _config = effectiveConfig;
    JourneyLogger.configure(
      debugLogging: effectiveConfig.debugLogging,
      appId: effectiveConfig.appId,
    );

    JourneyLogger.i(
      'Initializing v${JourneyConfig.sdkVersion} → ${effectiveConfig.baseUrl} '
      '(appId=${effectiveConfig.appId})',
    );

    // 1. Initialize Hive Persistent Box
    await HiveEventQueue.init();

    // 2. Resolve or generate consistent hardware/system Device ID
    final savedId = HiveEventQueue.getSavedDeviceId();
    _deviceId = await DeviceIdentifier.getDeviceId(
      persistedId: savedId,
      onSaveId: (id) => HiveEventQueue.saveDeviceId(id),
    );
    JourneyLogger.i('deviceId=$_deviceId');

    // 3. Initialize Session Manager & API Client
    final sessionManager = SessionManager(config: effectiveConfig);
    final session = await sessionManager.initializeSession(deviceId: _deviceId!);
    JourneyLogger.i('sessionId=${session.sessionId} status=${session.status}');

    final apiClient = JourneyApiClient(config: effectiveConfig);

    // 4. Initialize BLoC Worker
    _bloc = JourneyBloc(
      config: effectiveConfig,
      sessionManager: sessionManager,
      apiClient: apiClient,
      initialDeviceId: _deviceId!,
    );

    // 5. Track initial app launch event automatically
    track(
      'app_launch',
      {
        'appId': effectiveConfig.appId,
        'sdkVersion': JourneyConfig.sdkVersion,
        'baseUrl': effectiveConfig.baseUrl,
        'isFirstSession': session.eventsCount == 0,
      },
      'lifecycle',
    );
    JourneyLogger.i('Ready — tracking to shared backend');
  }

  /// Alias for init (accepts either JourneyConfig or String appId)
  static Future<void> initialize([dynamic configOrAppId]) async {
    if (configOrAppId is JourneyConfig) {
      await init(config: configOrAppId);
    } else if (configOrAppId is String) {
      await init(appId: configOrAppId);
    } else {
      await init();
    }
  }

  // ── Core Tracking Methods ──────────────────────────────────────────────────

  /// General unified event tracking
  static void track(
    String eventName, [
    Map<String, dynamic>? payload,
    String? eventType,
    String? contractId,
    String? templateId,
  ]) {
    if (!isInitialized) {
      JourneyLogger.w('track("$eventName") ignored — SDK not initialized');
      return;
    }
    _bloc!.add(TrackEventRequested(
      eventType: eventType ?? 'custom',
      eventName: eventName,
      payload: payload ?? {},
      contractId: contractId,
      templateId: templateId,
    ));
  }

  /// Track screen view transition
  static void trackScreen({
    required String screenName,
    String? previousScreenName,
    Map<String, dynamic>? metadata,
  }) {
    if (!isInitialized) return;
    _bloc!.add(ScreenViewRequested(
      screenName: screenName,
      previousScreenName: previousScreenName,
      metadata: metadata ?? {},
    ));
  }

  /// Track search queries with result counts
  static void trackSearch({
    required String query,
    int? resultCount,
    String? searchCategory,
    Map<String, dynamic>? extra,
  }) {
    track(
      'search_performed',
      {
        'query': query,
        if (resultCount != null) 'resultCount': resultCount,
        if (searchCategory != null) 'category': searchCategory,
        ...(extra ?? {}),
      },
      'search',
    );
  }

  /// Track user input fields, forms, and prompt entries
  static void trackUserInput({
    required String inputField,
    int? charCount,
    String? maskedValue,
    Map<String, dynamic>? extra,
  }) {
    track(
      'user_input',
      {
        'field': inputField,
        if (charCount != null) 'charCount': charCount,
        if (maskedValue != null) 'sample': maskedValue,
        ...(extra ?? {}),
      },
      'input',
    );
  }

  /// Track AI generations (prompts, completions, models, tokens, latency)
  static void trackAiGeneration({
    required String model,
    required bool success,
    String? promptCategory,
    int? promptLength,
    int? latencyMs,
    String? error,
    Map<String, dynamic>? extra,
  }) {
    track(
      success ? 'ai_generation_success' : 'ai_generation_failed',
      {
        'model': model,
        'success': success,
        if (promptCategory != null) 'category': promptCategory,
        if (promptLength != null) 'promptLength': promptLength,
        if (latencyMs != null) 'latencyMs': latencyMs,
        if (error != null) 'error': error,
        ...(extra ?? {}),
      },
      'ai',
    );
  }

  /// Track AdMob or other ad events with monetization details
  static void trackAd({
    required String adType, // 'banner', 'interstitial', 'rewarded', 'rewarded_interstitial', 'app_open'
    required String action, // 'impression', 'clicked', 'reward_earned', 'failed', 'opened', 'closed'
    String? adUnitId,
    num? rewardAmount,
    String? rewardType,
    String? placement,
    String? network = 'admob',
    Map<String, dynamic>? extra,
  }) {
    track(
      'ad_$action',
      {
        'adType': adType,
        'action': action,
        if (adUnitId != null) 'adUnitId': adUnitId,
        if (rewardAmount != null) 'rewardAmount': rewardAmount,
        if (rewardType != null) 'rewardType': rewardType,
        if (placement != null) 'placement': placement,
        'network': network,
        ...(extra ?? {}),
      },
      'ads',
    );
  }

  /// Track key conversion milestones
  static void trackMilestone(
    String milestoneName, {
    Map<String, dynamic>? details,
  }) {
    track(
      'milestone_$milestoneName',
      {
        'milestone': milestoneName,
        ...(details ?? {}),
      },
      'milestone',
    );
  }

  /// Track UI taps / clicks with element identity (reuse across apps)
  static void trackTap({
    required String element,
    String? elementType,
    String? targetId,
    String? source,
    Map<String, dynamic>? extra,
  }) {
    track(
      'ui_tap',
      {
        'element': element,
        if (elementType != null) 'elementType': elementType,
        if (targetId != null) 'targetId': targetId,
        if (source != null) 'source': source,
        ...(extra ?? {}),
      },
      'interaction',
    );
  }

  /// Track handled errors / crashes for product quality signals
  static void trackError({
    required String error,
    String? where,
    String? stackTrace,
    Map<String, dynamic>? extra,
  }) {
    track(
      'app_error',
      {
        'error': error,
        if (where != null) 'where': where,
        if (stackTrace != null)
          'stackTrace': stackTrace.length > 1500
              ? stackTrace.substring(0, 1500)
              : stackTrace,
        ...(extra ?? {}),
      },
      'error',
    );
  }

  /// Track in-app purchases and subscriptions
  static void trackPurchase({
    required String planId,
    required double amount,
    required String currency,
    bool success = true,
    String? transactionId,
    Map<String, dynamic>? extra,
  }) {
    track(
      success ? 'purchase_success' : 'purchase_failed',
      {
        'planId': planId,
        'amount': amount,
        'currency': currency,
        'success': success,
        if (transactionId != null) 'transactionId': transactionId,
        ...(extra ?? {}),
      },
      'monetization',
    );
  }

  /// Track notification open / receive / dismiss (FCM etc.)
  static void trackNotification({
    required String action, // received | opened | dismissed | tapped
    String? notificationId,
    String? title,
    String? campaign,
    Map<String, dynamic>? extra,
  }) {
    track(
      'notification_$action',
      {
        'action': action,
        if (notificationId != null) 'notificationId': notificationId,
        if (title != null) 'title': title,
        if (campaign != null) 'campaign': campaign,
        ...(extra ?? {}),
      },
      'notification',
    );
  }

  /// Pending events still waiting to flush (debug / health checks)
  static int get pendingEventsCount =>
      isInitialized ? HiveEventQueue.pendingEventsCount : 0;

  // ── User Identity ─────────────────────────────────────────────────────────

  /// Link guest sessions with user account upon login/register
  static void identify({
    required String userId,
    String? email,
    Map<String, dynamic>? traits,
  }) {
    if (!isInitialized) return;
    _bloc!.add(IdentifyUserRequested(
      userId: userId,
      email: email,
      traits: traits ?? {},
    ));
  }

  /// Reset identity upon logout
  static void logout() {
    if (!isInitialized) return;
    _bloc!.add(ResetIdentityRequested());
  }

  /// Force flush all buffered events to backend immediately
  static void flush() {
    if (!isInitialized) return;
    _bloc!.add(FlushQueueRequested(isForced: true));
  }

  /// Internal handler for app lifecycle events
  static void handleLifecycleChange(String state) {
    if (!isInitialized) return;
    _bloc!.add(AppLifecycleChanged(lifecycleState: state));
  }
}
