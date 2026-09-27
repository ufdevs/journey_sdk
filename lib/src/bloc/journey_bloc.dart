import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import '../api/journey_api_client.dart';
import '../config/journey_config.dart';
import '../core/session_manager.dart';
import '../models/tracked_event.dart';
import '../storage/hive_event_queue.dart';
import 'journey_event.dart';
import 'journey_state.dart';

/// Core BLoC managing event queueing, session rotation, and background batch flushing
class JourneyBloc extends Bloc<JourneyEvent, JourneyState> {
  final JourneyConfig config;
  final SessionManager sessionManager;
  final JourneyApiClient apiClient;
  Timer? _periodicFlushTimer;

  JourneyBloc({
    required this.config,
    required this.sessionManager,
    required this.apiClient,
    required String initialDeviceId,
  }) : super(JourneyState(deviceId: initialDeviceId)) {
    on<TrackEventRequested>(_onTrackEvent);
    on<ScreenViewRequested>(_onScreenView);
    on<FlushQueueRequested>(_onFlushQueue);
    on<IdentifyUserRequested>(_onIdentifyUser);
    on<ResetIdentityRequested>(_onResetIdentity);
    on<AppLifecycleChanged>(_onAppLifecycleChanged);

    _startPeriodicFlushTimer();
  }

  void _startPeriodicFlushTimer() {
    _periodicFlushTimer?.cancel();
    _periodicFlushTimer = Timer.periodic(config.flushInterval, (_) {
      add(FlushQueueRequested());
    });
  }

  Future<void> _onTrackEvent(TrackEventRequested event, Emitter<JourneyState> emit) async {
    try {
      final session = await sessionManager.ensureActiveSession(
        deviceId: state.deviceId,
        currentScreen: state.activeScreen,
      );

      final seqNo = sessionManager.nextSequenceNumber();
      final trackedEvent = TrackedEvent(
        id: const Uuid().v4(),
        appId: config.appId,
        sessionId: session.sessionId,
        seqNo: seqNo,
        deviceId: state.deviceId,
        userId: session.userId,
        userEmail: session.userEmail,
        eventType: event.eventType,
        eventName: event.eventName,
        payload: event.payload,
        contractId: event.contractId,
        templateId: event.templateId,
        timestamp: event.timestamp ?? DateTime.now(),
      );

      await HiveEventQueue.enqueueEvent(trackedEvent);

      final pendingCount = HiveEventQueue.pendingEventsCount;
      emit(state.copyWith(
        currentSession: session,
        pendingEventsCount: pendingCount,
      ));

      // Auto flush if batch threshold reached
      if (pendingCount >= config.batchSize) {
        add(FlushQueueRequested(isForced: true));
      }
    } catch (e) {
      emit(state.copyWith(lastError: e.toString()));
    }
  }

  Future<void> _onScreenView(ScreenViewRequested event, Emitter<JourneyState> emit) async {
    try {
      final session = await sessionManager.ensureActiveSession(
        deviceId: state.deviceId,
        currentScreen: event.screenName,
      );

      if (session.entryScreen == null) {
        session.entryScreen = event.screenName;
        await HiveEventQueue.saveActiveSession(session);
      }

      final seqNo = sessionManager.nextSequenceNumber();
      final trackedEvent = TrackedEvent(
        id: const Uuid().v4(),
        appId: config.appId,
        sessionId: session.sessionId,
        seqNo: seqNo,
        deviceId: state.deviceId,
        userId: session.userId,
        userEmail: session.userEmail,
        eventType: 'screen_view',
        eventName: event.screenName,
        payload: {
          'screenName': event.screenName,
          if (event.previousScreenName != null) 'previousScreen': event.previousScreenName,
          ...event.metadata,
        },
        timestamp: DateTime.now(),
      );

      await HiveEventQueue.enqueueEvent(trackedEvent);

      emit(state.copyWith(
        activeScreen: event.screenName,
        currentSession: session,
        pendingEventsCount: HiveEventQueue.pendingEventsCount,
      ));
    } catch (e) {
      emit(state.copyWith(lastError: e.toString()));
    }
  }

  Future<void> _onFlushQueue(FlushQueueRequested event, Emitter<JourneyState> emit) async {
    if (state.isFlushing) return;

    final pending = HiveEventQueue.peekEvents(limit: config.batchSize * 2);
    if (pending.isEmpty && sessionManager.currentSession == null) return;

    emit(state.copyWith(isFlushing: true));

    try {
      final session = sessionManager.currentSession ??
          await sessionManager.ensureActiveSession(deviceId: state.deviceId);

      final success = await apiClient.sendBatch(
        deviceId: state.deviceId,
        session: session,
        events: pending,
        userId: session.userId,
        userEmail: session.userEmail,
        userTraits: session.userTraits,
      );

      if (success) {
        final idsToRemove = pending.map((e) => e.id).toList();
        await HiveEventQueue.removeEvents(idsToRemove);
      }

      emit(state.copyWith(
        isFlushing: false,
        pendingEventsCount: HiveEventQueue.pendingEventsCount,
        lastError: success ? null : 'Failed to sync batch to server',
      ));
    } catch (e) {
      emit(state.copyWith(isFlushing: false, lastError: e.toString()));
    }
  }

  Future<void> _onIdentifyUser(IdentifyUserRequested event, Emitter<JourneyState> emit) async {
    await HiveEventQueue.saveUserIdentity(
      userId: event.userId,
      email: event.email,
      traits: event.traits,
    );

    await sessionManager.attachUserIdentity(
      userId: event.userId,
      email: event.email,
      traits: event.traits,
    );

    // Track identity event
    add(TrackEventRequested(
      eventType: 'user_identify',
      eventName: 'User Identified',
      payload: {
        'userId': event.userId,
        if (event.email != null) 'email': event.email,
        ...event.traits,
      },
    ));
  }

  Future<void> _onResetIdentity(ResetIdentityRequested event, Emitter<JourneyState> emit) async {
    add(TrackEventRequested(
      eventType: 'user_logout',
      eventName: 'User Logged Out',
    ));

    await HiveEventQueue.clearUserIdentity();
    // Flush current events before resetting session
    add(FlushQueueRequested(isForced: true));
  }

  Future<void> _onAppLifecycleChanged(AppLifecycleChanged event, Emitter<JourneyState> emit) async {
    if (event.lifecycleState == 'paused' || event.lifecycleState == 'inactive') {
      // App moving to background -> update session duration and flush queue immediately
      await sessionManager.endSession();
      add(FlushQueueRequested(isForced: true));
    } else if (event.lifecycleState == 'resumed') {
      // App coming back -> check if timeout exceeded, start new session if needed
      await sessionManager.ensureActiveSession(deviceId: state.deviceId);
    }
  }

  @override
  Future<void> close() {
    _periodicFlushTimer?.cancel();
    apiClient.dispose();
    return super.close();
  }
}
