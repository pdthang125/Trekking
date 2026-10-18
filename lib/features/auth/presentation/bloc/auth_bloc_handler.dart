import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;

import 'auth_bloc.dart';

@injectable
class AuthBlocHandler extends Bloc<AuthEvent, AuthState> {
  final SupabaseClient _supabase;

  AuthBlocHandler(this._supabase) : super(const AuthInitial()) {
    on<CheckAuthStatusEvent>(_onCheckStatus);
    on<LoginWithEmailEvent>(_onLogin);
    on<RegisterWithEmailEvent>(_onRegister);
    on<ContinueAnonymousEvent>(_onAnonymous);
    on<LogoutEvent>(_onLogout);
  }

  Future<void> _onCheckStatus(CheckAuthStatusEvent event, Emitter<AuthState> emit) async {
    final session = _supabase.auth.currentSession;
    if (session != null) {
      final user = _supabase.auth.currentUser;
      emit(AuthAuthenticated(
        userId: user!.id,
        displayName: user.userMetadata?['display_name'] as String?,
      ));
    } else {
      emit(const AuthUnauthenticated());
    }
  }

  Future<void> _onLogin(LoginWithEmailEvent event, Emitter<AuthState> emit) async {
    emit(const AuthLoading());
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: event.email,
        password: event.password,
      );
      if (response.user != null) {
        emit(AuthAuthenticated(
          userId: response.user!.id,
          displayName: response.user!.userMetadata?['display_name'] as String?,
        ));
      }
    } on AuthException catch (e) {
      emit(AuthError(message: _translateAuthError(e.message)));
    } catch (e) {
      emit(AuthError(message: e.toString()));
    }
  }

  Future<void> _onRegister(RegisterWithEmailEvent event, Emitter<AuthState> emit) async {
    emit(const AuthLoading());
    try {
      final response = await _supabase.auth.signUp(
        email: event.email,
        password: event.password,
        data: {'display_name': event.displayName ?? event.email.split('@')[0]},
      );
      if (response.user != null) {
        emit(AuthAuthenticated(
          userId: response.user!.id,
          displayName: event.displayName,
        ));
      }
    } on AuthException catch (e) {
      emit(AuthError(message: _translateAuthError(e.message)));
    } catch (e) {
      emit(AuthError(message: e.toString()));
    }
  }

  Future<void> _onAnonymous(ContinueAnonymousEvent event, Emitter<AuthState> emit) async {
    // Skip auth — use local mode only
    emit(const AuthAuthenticated(
      userId: 'anonymous',
      displayName: 'Khách',
      isAnonymous: true,
    ));
  }

  Future<void> _onLogout(LogoutEvent event, Emitter<AuthState> emit) async {
    await _supabase.auth.signOut();
    emit(const AuthUnauthenticated());
  }

  String _translateAuthError(String message) {
    if (message.contains('Invalid login credentials')) return 'Email hoặc mật khẩu không đúng';
    if (message.contains('Email not confirmed')) return 'Vui lòng xác nhận email trước khi đăng nhập';
    if (message.contains('User already registered')) return 'Email này đã được đăng ký';
    if (message.contains('Password should be at least')) return 'Mật khẩu phải có ít nhất 6 ký tự';
    return message;
  }
}
