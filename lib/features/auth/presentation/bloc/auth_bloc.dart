import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// ─── States ──────────────────────────────────────────────────────────────────

abstract class AuthState extends Equatable {
  const AuthState();
  @override List<Object?> get props => [];
}

class AuthInitial extends AuthState { const AuthInitial(); }
class AuthLoading extends AuthState { const AuthLoading(); }

class AuthAuthenticated extends AuthState {
  final String userId;
  final String? displayName;
  final bool isAnonymous;
  const AuthAuthenticated({required this.userId, this.displayName, this.isAnonymous = false});
  @override List<Object?> get props => [userId, isAnonymous];
}

class AuthUnauthenticated extends AuthState { const AuthUnauthenticated(); }

class AuthError extends AuthState {
  final String message;
  const AuthError({required this.message});
  @override List<Object?> get props => [message];
}

// ─── Events ──────────────────────────────────────────────────────────────────

abstract class AuthEvent extends Equatable {
  const AuthEvent();
  @override List<Object?> get props => [];
}

class CheckAuthStatusEvent extends AuthEvent { const CheckAuthStatusEvent(); }

class LoginWithEmailEvent extends AuthEvent {
  final String email;
  final String password;
  const LoginWithEmailEvent({required this.email, required this.password});
  @override List<Object?> get props => [email];
}

class RegisterWithEmailEvent extends AuthEvent {
  final String email;
  final String password;
  final String? displayName;
  const RegisterWithEmailEvent({required this.email, required this.password, this.displayName});
  @override List<Object?> get props => [email];
}

class ContinueAnonymousEvent extends AuthEvent { const ContinueAnonymousEvent(); }

class LogoutEvent extends AuthEvent { const LogoutEvent(); }

// ─── Bloc ────────────────────────────────────────────────────────────────────

/// Placeholder AuthBloc - TODO: Implement with actual auth logic
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc() : super(const AuthInitial()) {
    on<CheckAuthStatusEvent>(_onCheckAuthStatus);
    on<LoginWithEmailEvent>(_onLoginWithEmail);
    on<RegisterWithEmailEvent>(_onRegisterWithEmail);
    on<ContinueAnonymousEvent>(_onContinueAnonymous);
    on<LogoutEvent>(_onLogout);
  }

  Future<void> _onCheckAuthStatus(
    CheckAuthStatusEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    // TODO: Check actual auth status
    await Future.delayed(const Duration(milliseconds: 500));
    emit(const AuthUnauthenticated());
  }

  Future<void> _onLoginWithEmail(
    LoginWithEmailEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    // TODO: Implement actual login
    await Future.delayed(const Duration(seconds: 1));
    emit(const AuthAuthenticated(userId: 'temp-user-id'));
  }

  Future<void> _onRegisterWithEmail(
    RegisterWithEmailEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    // TODO: Implement actual registration
    await Future.delayed(const Duration(seconds: 1));
    emit(const AuthAuthenticated(userId: 'temp-user-id'));
  }

  Future<void> _onContinueAnonymous(
    ContinueAnonymousEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    // TODO: Implement anonymous login
    await Future.delayed(const Duration(milliseconds: 500));
    emit(const AuthAuthenticated(
      userId: 'anonymous-user',
      isAnonymous: true,
    ));
  }

  Future<void> _onLogout(
    LogoutEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    // TODO: Implement actual logout
    await Future.delayed(const Duration(milliseconds: 300));
    emit(const AuthUnauthenticated());
  }
}
