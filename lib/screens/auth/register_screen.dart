import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/text_styles.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common/gold_button.dart';

class RegisterScreen extends StatefulWidget {
  final bool showBackButton;
  final VoidCallback? onSwitchToLogin;
  const RegisterScreen({
    super.key,
    this.showBackButton = true,
    this.onSwitchToLogin,
  });

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey   = GlobalKey<FormState>();
  final _nomCtrl   = TextEditingController();
  final _telCtrl   = TextEditingController();
  final _waCtrl    = TextEditingController();
  final _passCtrl  = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _obscurePass    = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _nomCtrl.dispose(); _telCtrl.dispose(); _waCtrl.dispose();
    _passCtrl.dispose(); _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final ok = await auth.register(
      nom:       _nomCtrl.text.trim(),
      telephone: _telCtrl.text.trim(),
      whatsapp:  _waCtrl.text.trim().isEmpty ? _telCtrl.text.trim() : _waCtrl.text.trim(),
      password:  _passCtrl.text,
    );
    if (ok && mounted) context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: kWhite,
      appBar: AppBar(
        backgroundColor: kNavBar,
        title: Image.asset(
          'assets/images/IMMOROYAL_4_1.png',
          height: 50,
          fit: BoxFit.contain,
        )
      ),
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

                Text('Créer un compte', style: AppText.pageTitle),
                const SizedBox(height: 6),
                Text('Renseignez vos informations pour vous inscrire', style: AppText.bodySmall),
                const SizedBox(height: 32),

                _Field(label: 'Nom complet', ctrl: _nomCtrl, hint: 'Steed Noumon',
                    icon: Icons.person_outline,
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Nom requis' : null),
                const SizedBox(height: 16),

                _Field(label: 'Numéro de téléphone', ctrl: _telCtrl, hint: '+2290197000000',
                    icon: Icons.phone_outlined, type: TextInputType.phone,
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Téléphone requis' : null),
                const SizedBox(height: 16),

                _Field(label: 'Numéro WhatsApp (optionnel)', ctrl: _waCtrl,
                    hint: 'Laisser vide = même que téléphone',
                    icon: Icons.chat_outlined, type: TextInputType.phone),
                const SizedBox(height: 16),

                // Mot de passe
                Text('Mot de passe', style: AppText.label),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _passCtrl,
                  obscureText: _obscurePass,
                  decoration: InputDecoration(
                    hintText: '••••••••',
                    prefixIcon: const Icon(Icons.lock_outline, size: 20),
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePass ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 20),
                      onPressed: () => setState(() => _obscurePass = !_obscurePass),
                    ),
                  ),
                  validator: (v) => (v == null || v.length < 6) ? 'Min. 6 caractères' : null,
                ),
                const SizedBox(height: 16),

                // Confirmer
                Text('Confirmer le mot de passe', style: AppText.label),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _confirmCtrl,
                  obscureText: _obscureConfirm,
                  decoration: InputDecoration(
                    hintText: '••••••••',
                    prefixIcon: const Icon(Icons.lock_outline, size: 20),
                    suffixIcon: IconButton(
                      icon: Icon(_obscureConfirm ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 20),
                      onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                    ),
                  ),
                  validator: (v) => v != _passCtrl.text ? 'Les mots de passe ne correspondent pas' : null,
                ),

                // Erreur API
                if (auth.error != null) ...[
                  const SizedBox(height: 16),
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

                GoldButton(
                  label: "S'inscrire",
                  icon: Icons.person_add_outlined,
                  loading: auth.isLoading,
                  onPressed: _submit,
                ),
                const SizedBox(height: 16),

                Center(
                  child: GestureDetector(
                    onTap: () {
                      if (widget.onSwitchToLogin != null) {
                        widget.onSwitchToLogin!();
                      } else {
                        context.push('/login');
                      }
                    },
                    child: RichText(
                      text: TextSpan(
                        style: AppText.bodySmall,
                        children: [
                          const TextSpan(text: 'Déjà un compte ? '),
                          TextSpan(
                            text: 'Se connecter',
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

class _Field extends StatelessWidget {
  final String label;
  final TextEditingController ctrl;
  final String? hint;
  final IconData? icon;
  final TextInputType? type;
  final String? Function(String?)? validator;

  const _Field({
    required this.label,
    required this.ctrl,
    this.hint,
    this.icon,
    this.type,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: kBlack)),
        const SizedBox(height: 8),
        TextFormField(
          controller: ctrl,
          keyboardType: type,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: icon != null ? Icon(icon, size: 20) : null,
          ),
          validator: validator,
        ),
      ],
    );
  }
}
