import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/profile.dart';

class UserState {
  final Session? session;
  final Profile? profile;
  final bool isLoading;

  UserState({this.session, this.profile, this.isLoading = false});

  UserState copyWith({Session? session, Profile? profile, bool? isLoading}) {
    return UserState(
      session: session ?? this.session,
      profile: profile ?? this.profile,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  bool get isAdmin => profile?.role == 'admin';
  bool get isAuthenticated => session != null;
}

class AuthNotifier extends StateNotifier<UserState> {
  final Logger logger = Logger();

  AuthNotifier() : super(UserState(isLoading: true)) {
    _authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen(
      (data) {
        final AuthChangeEvent event = data.event;
        final Session? session = data.session;
        _handleAuthStateChange(event, session);
      },
      onError: (error) {
        logger.e('Auth state stream error: $error');
        state = UserState(
          session: state.session,
          profile: state.profile,
          isLoading: false,
        );
      },
    );

    final initialSessionData = Supabase.instance.client.auth.currentSession;
    final initialEvent =
        initialSessionData != null
            ? AuthChangeEvent.initialSession
            : AuthChangeEvent.signedOut;

    final initialAuthStateData = AuthState(initialEvent, initialSessionData);

    _handleAuthStateChange(
      initialAuthStateData.event,
      initialAuthStateData.session,
    );
  }

  late final StreamSubscription<AuthState> _authSubscription;

  @override
  void dispose() {
    _authSubscription.cancel();
    super.dispose();
  }

  void _handleAuthStateChange(AuthChangeEvent event, Session? session) {
    logger.i(
      'Auth event caught by AuthNotifier: $event, Session: ${session != null ? 'Exists' : 'Null'}',
    );

    switch (event) {
      case AuthChangeEvent.initialSession:
      case AuthChangeEvent.signedIn:
      case AuthChangeEvent.tokenRefreshed:
        if (session != null) {
          state = state.copyWith(session: session);
          if (state.profile == null || state.profile!.id != session.user.id) {
            logger.i(
              'AuthNotifier: Session active, loading/reloading profile...',
            );
            if (!state.isLoading) {
              state = state.copyWith(isLoading: true);
            }
            _loadProfile(session.user.id);
          } else {
            logger.i('AuthNotifier: Session active, profile already loaded.');
            state = state.copyWith(isLoading: false);
          }
        } else {
          logger.i(
            'AuthNotifier: Auth event $event with null session. Clearing state.',
          );
          state = UserState(session: null, profile: null, isLoading: false);
        }
        break;

      case AuthChangeEvent.signedOut:
        logger.i('AuthNotifier: User signed out or deleted. Clearing state.');
        state = UserState(session: null, profile: null, isLoading: false);
        break;

      case AuthChangeEvent.passwordRecovery:
        logger.i(
          'AuthNotifier: Password recovery event. Session state: ${session != null ? 'valid' : 'null'}',
        );
        state = state.copyWith(isLoading: false);
        break;
      case AuthChangeEvent.userUpdated:
        logger.i('AuthNotifier: User updated event. Reloading profile...');
        if (state.session != null) {
          if (!state.isLoading) {
            state = state.copyWith(isLoading: true);
          }
          _loadProfile(state.session!.user.id, forceReload: true);
        } else {
          logger.i(
            'AuthNotifier: User updated event but no active session. Cannot reload profile.',
          );
          state = state.copyWith(isLoading: false);
        }
        break;

      default:
        logger.i(
          'AuthNotifier: Unhandled AuthChangeEvent: $event. Session state: ${session != null ? 'valid' : 'null'}',
        );
        state = state.copyWith(isLoading: false);
        break;
    }
  }

  Future<void> _loadProfile(String userId, {bool forceReload = false}) async {
    try {
      final response =
          await Supabase.instance.client
              .from('profiles')
              .select('*')
              .eq('id', userId)
              .single();

      final profile = Profile.fromJson(response);

      logger.i('AuthNotifier: Profile loaded successfully for user $userId');
      state = state.copyWith(profile: profile, isLoading: false);
    } on PostgrestException catch (e) {
      logger.e('Error loading user profile $userId: ${e.message}');

      state = state.copyWith(profile: null, isLoading: false);
    } catch (e) {
      logger.e('Unexpected error loading profile for user $userId: $e');
      state = state.copyWith(profile: null, isLoading: false);
    }
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, UserState>((ref) {
  return AuthNotifier();
});
