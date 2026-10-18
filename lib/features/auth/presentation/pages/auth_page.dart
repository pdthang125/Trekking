import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';

/// Auth screen — Login / Register with Supabase
class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: AppTheme.dangerColor),
            );
          }
        },
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const SizedBox(height: 32),
                // ── Logo ─────────────────────────────────────────
                Container(
                  width: 80, height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(colors: [
                      AppTheme.safeColor, AppTheme.safeColor.withAlpha(180),
                    ]),
                  ),
                  child: const Icon(Icons.terrain_rounded, size: 42, color: Colors.black),
                ),
                const SizedBox(height: 16),
                Text('TrekGuard AI', style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                )),
                Text('Người đồng hành leo núi thông minh',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withAlpha(150),
                  ),
                ),
                const SizedBox(height: 32),

                // ── Tab Bar ───────────────────────────────────────
                Container(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    indicator: BoxDecoration(
                      color: theme.colorScheme.primary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    indicatorSize: TabBarIndicatorSize.tab,
                    dividerColor: Colors.transparent,
                    labelColor: Colors.black,
                    unselectedLabelColor: theme.colorScheme.onSurface.withAlpha(150),
                    tabs: const [
                      Tab(text: 'Đăng nhập'),
                      Tab(text: 'Đăng ký'),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // ── Forms ─────────────────────────────────────────
                SizedBox(
                  height: 280,
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _LoginForm(
                        email: _emailController,
                        password: _passwordController,
                        obscure: _obscurePassword,
                        onToggleObscure: () => setState(() => _obscurePassword = !_obscurePassword),
                      ),
                      _RegisterForm(
                        email: _emailController,
                        password: _passwordController,
                        name: _nameController,
                        obscure: _obscurePassword,
                        onToggleObscure: () => setState(() => _obscurePassword = !_obscurePassword),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),

                // ── Anonymous / Skip ──────────────────────────────
                const Divider(),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  icon: const Icon(Icons.person_outline_rounded),
                  label: const Text('Tiếp tục không cần tài khoản'),
                  onPressed: () {
                    context.read<AuthBloc>().add(const ContinueAnonymousEvent());
                  },
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }
}

class _LoginForm extends StatelessWidget {
  final TextEditingController email, password;
  final bool obscure;
  final VoidCallback onToggleObscure;
  const _LoginForm({required this.email, required this.password, required this.obscure, required this.onToggleObscure});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(controller: email, decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email_rounded))),
        const SizedBox(height: 12),
        TextField(
          controller: password, obscureText: obscure,
          decoration: InputDecoration(
            labelText: 'Mật khẩu',
            prefixIcon: const Icon(Icons.lock_rounded),
            suffixIcon: IconButton(icon: Icon(obscure ? Icons.visibility_rounded : Icons.visibility_off_rounded), onPressed: onToggleObscure),
          ),
        ),
        const SizedBox(height: 20),
        BlocBuilder<AuthBloc, AuthState>(
          builder: (context, state) => FilledButton(
            onPressed: state is AuthLoading ? null : () {
              context.read<AuthBloc>().add(LoginWithEmailEvent(email: email.text, password: password.text));
            },
            style: FilledButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
            child: state is AuthLoading
                ? const CircularProgressIndicator(color: Colors.black)
                : const Text('Đăng nhập'),
          ),
        ),
      ],
    );
  }
}

class _RegisterForm extends StatelessWidget {
  final TextEditingController email, password, name;
  final bool obscure;
  final VoidCallback onToggleObscure;
  const _RegisterForm({required this.email, required this.password, required this.name, required this.obscure, required this.onToggleObscure});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(controller: name, decoration: const InputDecoration(labelText: 'Tên hiển thị', prefixIcon: Icon(Icons.person_rounded))),
        const SizedBox(height: 8),
        TextField(controller: email, decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email_rounded))),
        const SizedBox(height: 8),
        TextField(controller: password, obscureText: obscure, decoration: InputDecoration(labelText: 'Mật khẩu', prefixIcon: const Icon(Icons.lock_rounded), suffixIcon: IconButton(icon: Icon(obscure ? Icons.visibility_rounded : Icons.visibility_off_rounded), onPressed: onToggleObscure))),
        const SizedBox(height: 12),
        BlocBuilder<AuthBloc, AuthState>(
          builder: (context, state) => FilledButton(
            onPressed: state is AuthLoading ? null : () {
              context.read<AuthBloc>().add(RegisterWithEmailEvent(email: email.text, password: password.text, displayName: name.text));
            },
            style: FilledButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
            child: state is AuthLoading ? const CircularProgressIndicator(color: Colors.black) : const Text('Đăng ký'),
          ),
        ),
      ],
    );
  }
}
