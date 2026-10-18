import 'package:equatable/equatable.dart';

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
