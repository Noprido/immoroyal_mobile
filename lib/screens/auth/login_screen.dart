import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/text_styles.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common/gold_button.dart';

class LoginScreen extends StatefulWidget {
  final bool showBackButton;
  final VoidCallback? onSwitchToRegister;
  const LoginScreen({
    super.key,
    this.showBackButton = true,
    this.onSwitchToRegister,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey   = GlobalKey<FormState>();
  final _telCtrl   = TextEditingController();
  final _passCtrl  = TextEditingController();
  bool _obscure    = true;

  @override
  void dispose() {
    _telCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final ok = await auth.login(_telCtrl.text.trim(), _passCtrl.text);
    if (ok && mounted) context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: kNavBar,
        title: Image.asset(
          'assets/images/IMMOROYAL_4_1.png',
          height: 50,
          fit: BoxFit.contain,
        )
      ),
      backgroundColor: kWhite,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Logo
                // Image.asset('assets/images/IMMOROYAL_1_1.png', height: 60, fit: BoxFit.contain),
                const SizedBox(height: 32),

                // Titre
                Text('Connexion', style: AppText.pageTitle),
                const SizedBox(height: 6),
                Text('Entrez vos identifiants pour accéder à votre compte', style: AppText.bodySmall),
                const SizedBox(height: 32),

                // Téléphone
                Text('Numéro de téléphone', style: AppText.label),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _telCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    hintText: '+22990000000',
                    prefixIcon: Icon(Icons.phone_outlined, size: 20),
                  ),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Numéro requis' : null,
                ),
                const SizedBox(height: 20),

                // Mot de passe
                Text('Mot de passe', style: AppText.label),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _passCtrl,
                  obscureText: _obscure,
                  decoration: InputDecoration(
                    hintText: '••••••••',
                    prefixIcon: const Icon(Icons.lock_outline, size: 20),
                    suffixIcon: IconButton(
                      icon: Icon(_obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 20),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ),
                  validator: (v) =>
                      (v == null || v.isEmpty) ? 'Mot de passe requis' : null,
                ),
                const SizedBox(height: 10),

                // Erreur API
                if (auth.error != null) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: kRed.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: kRed.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: kRed, size: 18),
                        const SizedBox(width: 8),
                        Expanded(child: Text(auth.error!, style: AppText.bodySmall.copyWith(color: kRed))),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 28),

                // Bouton connexion
                GoldButton(
                  label: 'Se connecter',
                  icon: Icons.login,
                  loading: auth.isLoading,
                  onPressed: _submit,
                ),
                const SizedBox(height: 16),

                // Lien inscription
                Center(
                  child: GestureDetector(
                    onTap: () {
                      if (widget.onSwitchToRegister != null) {
                        widget.onSwitchToRegister!();
                      } else {
                        context.push('/register');
                      }
                    },
                    child: RichText(
                      text: TextSpan(
                        style: AppText.bodySmall,
                        children: [
                          const TextSpan(text: "Pas encore de compte ? "),
                          TextSpan(
                            text: "S'inscrire",
                            style: AppText.bodySmall.copyWith(
                              color: kGold,
                              fontWeight: FontWeight.w600,
                              decoration: TextDecoration.underline,
                              decorationColor: kGold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                SizedBox(height: 50 + MediaQuery.of(context).padding.bottom)
              ],
            ),
          ),
        ),
      ),
    );
  }
}
