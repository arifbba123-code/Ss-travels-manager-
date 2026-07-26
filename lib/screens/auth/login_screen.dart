import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import 'auth_loading_screen.dart';

/// SCREEN 1 — Login
///
/// Only registered mail IDs are allowed to sign in. There is no sign-up
/// button; unregistered users are told to contact the owner. After a
/// successful login, [AuthLoadingScreen] resolves the account's role and
/// routes to the correct dashboard (Owner / Admin / Driver).
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();

  bool _obscure = true;
  bool _rememberMe = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AuthLoadingScreen(
          email: _emailCtrl.text.trim(),
          password: _passCtrl.text,
        ),
      ),
    );
  }

  void _showContactOwnerSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.panel,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: AppColors.grey,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Text('Need an account?',
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text(
              'Access is by invitation only. Reach out to the business owner to '
              'get your Mail ID registered as Admin or Driver.',
              style: TextStyle(color: AppColors.grey, fontSize: 13, height: 1.5),
            ),
            const SizedBox(height: 20),
            _ContactRow(icon: Icons.call, label: '+91 98765 43210'),
            const SizedBox(height: 12),
            _ContactRow(icon: Icons.email_outlined, label: 'owner@sstours.com'),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.black,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const SizedBox(height: 24),
                        _Logo(),
                        const SizedBox(height: 14),
                        RichText(
                          textAlign: TextAlign.center,
                          text: const TextSpan(
                            children: [
                              TextSpan(
                                text: 'SS Tours & Travels\n',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.3,
                                  height: 1.3,
                                ),
                              ),
                              TextSpan(
                                text: 'Manager',
                                style: TextStyle(
                                  color: AppColors.gold,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 1.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 36),
                        const Align(
                          alignment: Alignment.centerLeft,
                          child: Text('Welcome Back',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 26,
                                  fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(height: 6),
                        const Align(
                          alignment: Alignment.centerLeft,
                          child: Text('Login to continue',
                              style: TextStyle(color: AppColors.grey, fontSize: 14)),
                        ),
                        const SizedBox(height: 28),
                        _FieldLabel('Email Address'),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _emailCtrl,
                          keyboardType: TextInputType.emailAddress,
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                            hintText: 'you@sstours.com',
                            prefixIcon: Icon(Icons.mail_outline, color: AppColors.grey),
                          ),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return 'Enter your registered mail ID';
                            if (!v.contains('@') || !v.contains('.')) return 'Enter a valid email';
                            return null;
                          },
                        ),
                        const SizedBox(height: 18),
                        _FieldLabel('Password'),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _passCtrl,
                          obscureText: _obscure,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: '••••••••••',
                            prefixIcon: const Icon(Icons.lock_outline, color: AppColors.grey),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                color: AppColors.grey,
                              ),
                              onPressed: () => setState(() => _obscure = !_obscure),
                            ),
                          ),
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'Enter your password';
                            return null;
                          },
                          onFieldSubmitted: (_) => _submit(),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            SizedBox(
                              width: 22,
                              height: 22,
                              child: Checkbox(
                                value: _rememberMe,
                                onChanged: (v) => setState(() => _rememberMe = v ?? true),
                                activeColor: AppColors.gold,
                                checkColor: Colors.black,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(4)),
                                side: const BorderSide(color: AppColors.grey),
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text('Remember me',
                                style: TextStyle(color: Colors.white, fontSize: 13)),
                            const Spacer(),
                            TextButton(
                              onPressed: () {},
                              style: TextButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  minimumSize: const Size(0, 0),
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                              child: const Text('Forgot Password?',
                                  style: TextStyle(
                                      color: AppColors.gold,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _submit,
                            style: ElevatedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20)),
                            ),
                            child: const Text('Login'),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            const Expanded(child: Divider(color: Color(0xFF2A2A2A))),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              child: Text('or continue with',
                                  style: TextStyle(color: AppColors.grey, fontSize: 12)),
                            ),
                            const Expanded(child: Divider(color: Color(0xFF2A2A2A))),
                          ],
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () {},
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: const BorderSide(color: Color(0xFF2A2A2A)),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20)),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            icon: const _GoogleG(),
                            label: const Text('Continue with Google',
                                style: TextStyle(fontWeight: FontWeight.w600)),
                          ),
                        ),
                        const SizedBox(height: 32),
                        GestureDetector(
                          onTap: _showContactOwnerSheet,
                          child: RichText(
                            text: TextSpan(
                              style: const TextStyle(color: AppColors.grey, fontSize: 13),
                              children: const [
                                TextSpan(text: "Don't have an account?  "),
                                TextSpan(
                                  text: 'Contact Owner',
                                  style: TextStyle(
                                      color: AppColors.gold, fontWeight: FontWeight.w700),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);
  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(text,
          style: const TextStyle(color: AppColors.grey, fontSize: 13, fontWeight: FontWeight.w500)),
    );
  }
}

class _Logo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 84,
      height: 84,
      decoration: BoxDecoration(
        color: AppColors.gold,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.gold.withValues(alpha: 0.35),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Image.asset(
          'assets/images/logo.png',
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => const Center(
            child: Text('SS',
                style: TextStyle(
                    color: Colors.black, fontSize: 30, fontWeight: FontWeight.w900)),
          ),
        ),
      ),
    );
  }
}

class _GoogleG extends StatelessWidget {
  const _GoogleG();
  @override
  Widget build(BuildContext context) {
    return const Text('G',
        style: TextStyle(
            color: AppColors.gold, fontWeight: FontWeight.w900, fontSize: 16));
  }
}

class _ContactRow extends StatelessWidget {
  final IconData icon;
  final String label;
  const _ContactRow({required this.icon, required this.label});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.panel2,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.gold, size: 20),
          const SizedBox(width: 12),
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 14)),
        ],
      ),
    );
  }
}
