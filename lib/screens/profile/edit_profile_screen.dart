import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/text_styles.dart';
import '../../core/network/dio_client.dart';
import '../../providers/auth_provider.dart';
import '../../models/user.dart';
import '../../widgets/common/gold_button.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});
  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey        = GlobalKey<FormState>();
  final _nomCtrl        = TextEditingController();
  final _waCtrl         = TextEditingController();
  final _bioCtrl        = TextEditingController();
  final _ancienPassCtrl = TextEditingController();
  final _newPassCtrl    = TextEditingController();
  
  String _typeVendeur = 'particulier';
  bool _loading       = false;
  bool _obscureAncien = true;
  bool _obscureNew    = true;
  String? _error;
  String? _success;

  final _typesVendeur = ['particulier', 'proprietaire', 'demarcheur'];

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().user;
    if (user != null) {
      _nomCtrl.text   = user.nom;
      _waCtrl.text    = user.whatsapp;
      _bioCtrl.text   = user.bio ?? '';
      _typeVendeur    = user.typeVendeur ?? 'particulier';
    }
  }

  @override
  void dispose() {
    _nomCtrl.dispose();
    _waCtrl.dispose();
    _bioCtrl.dispose();
    _ancienPassCtrl.dispose();
    _newPassCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _error = null; _success = null; });

    try {
      final body = <String, dynamic>{
        'nom':         _nomCtrl.text.trim(),
        'whatsapp':    _waCtrl.text.trim(),
        'bio':         _bioCtrl.text.trim(),
        'typeVendeur': _typeVendeur,
      };

      if (_newPassCtrl.text.isNotEmpty) {
        body['ancienPassword'] = _ancienPassCtrl.text;
        body['newPassword']    = _newPassCtrl.text;
      }

      final res = await DioClient.instance.put('/profile/modifier', data: body);
      final updated = UserModel.fromJson(res.data as Map<String, dynamic>);
      
      if (mounted) {
        context.read<AuthProvider>().updateUser(updated);
        setState(() => _loading = false);
        context.pop();
        _ancienPassCtrl.clear();
        _newPassCtrl.clear();
      }
    } catch (e) {
      if (mounted) setState(() {
        _error   = _extractError(e);
        _loading = false;
      });
    }
  }

  String _extractError(dynamic e) {
    try {
      final data = (e as dynamic).response?.data;
      if (data is Map) return (data['error'] ?? 'Erreur inconnue').toString();
    } catch (_) {}
    return 'Erreur de connexion.';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kWhite,
      appBar: AppBar(
        backgroundColor: kNavBar,
        leading: GestureDetector(
          onTap: () => context.pop(),
          child: const Icon(Icons.arrow_back_ios_new, color: kWhite, size: 20),
        ),
        title: const Text('Modifier mon profil', style: TextStyle(color: kWhite, fontSize: 18, fontWeight: FontWeight.w600)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // ── Message succès ──
              if (_success != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: kActiveGreen.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: kActiveGreen.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle_outline, color: kActiveGreen, size: 18),
                      const SizedBox(width: 8),
                      Expanded(child: Text(_success!, style: AppText.bodySmall.copyWith(color: kActiveGreen))),
                    ],
                  ),
                ),

              // ── Message erreur ──
              if (_error != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
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
                      Expanded(child: Text(_error!, style: AppText.bodySmall.copyWith(color: kRed))),
                    ],
                  ),
                ),

              // ── Infos personnelles ──
              _SectionTitle(label: 'Informations personnelles'),
              const SizedBox(height: 16),

              // Nom
              _Field(
                label: 'Nom complet',
                ctrl: _nomCtrl,
                icon: Icons.person_outline,
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Nom requis' : null,
              ),
              const SizedBox(height: 16),

              // Téléphone (non modifiable)
              _ReadonlyField(
                label: 'Téléphone (non modifiable)',
                value: context.read<AuthProvider>().user?.telephone ?? '',
                icon: Icons.phone_outlined,
              ),
              const SizedBox(height: 16),

              // WhatsApp
              _Field(
                label: 'Numéro WhatsApp',
                ctrl: _waCtrl,
                icon: Icons.chat_outlined,
                hint: 'Laisser vide = même que téléphone',
                type: TextInputType.phone,
              ),
              const SizedBox(height: 16),

              // Type vendeur
              Text('Type de vendeur', style: AppText.label),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _typeVendeur,
                decoration: const InputDecoration(prefixIcon: Icon(Icons.business_center_outlined, size: 18)),
                items: _typesVendeur.map((t) => DropdownMenuItem(
                  value: t,
                  child: Text(t[0].toUpperCase() + t.substring(1)),
                )).toList(),
                onChanged: (v) => setState(() => _typeVendeur = v!),
              ),
              const SizedBox(height: 16),

              // Bio
              Text('Bio (optionnel)', style: AppText.label),
              const SizedBox(height: 8),
              TextFormField(
                controller: _bioCtrl,
                maxLines: 4,
                decoration: const InputDecoration(
                  hintText: 'Présentez-vous en quelques mots...',
                  alignLabelWithHint: true,
                ),
              ),

              const SizedBox(height: 28),
              const Divider(),
              const SizedBox(height: 20),

              // ── Changer mot de passe ──
              _SectionTitle(label: 'Changer le mot de passe (optionnel)'),
              const SizedBox(height: 16),

              // Ancien mot de passe
              Text('Mot de passe actuel', style: AppText.label),
              const SizedBox(height: 8),
              TextFormField(
                controller: _ancienPassCtrl,
                obscureText: _obscureAncien,
                decoration: InputDecoration(
                  hintText: '••••••••',
                  prefixIcon: const Icon(Icons.lock_outline, size: 18),
                  suffixIcon: IconButton(
                    icon: Icon(_obscureAncien ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 18),
                    onPressed: () => setState(() => _obscureAncien = !_obscureAncien),
                  ),
                ),
                validator: (v) {
                  if (_newPassCtrl.text.isNotEmpty && (v == null || v.isEmpty)) {
                    return 'Saisissez votre mot de passe actuel';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Nouveau mot de passe
              Text('Nouveau mot de passe', style: AppText.label),
              const SizedBox(height: 8),
              TextFormField(
                controller: _newPassCtrl,
                obscureText: _obscureNew,
                decoration: InputDecoration(
                  hintText: '••••••••',
                  prefixIcon: const Icon(Icons.lock_outline, size: 18),
                  suffixIcon: IconButton(
                    icon: Icon(_obscureNew ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 18),
                    onPressed: () => setState(() => _obscureNew = !_obscureNew),
                  ),
                ),
                validator: (v) {
                  if (v != null && v.isNotEmpty && v.length < 6) {
                    return 'Min. 6 caractères';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 32),

              // ── Bouton enregistrer ──
              GoldButton(
                label: 'Enregistrer',
                icon: Icons.check,
                loading: _loading,
                onPressed: _submit,
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Widgets locaux ───────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String label;
  const _SectionTitle({required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 3, height: 18, color: kGold, margin: const EdgeInsets.only(right: 10)),
        Text(label, style: AppText.sectionTitle.copyWith(fontSize: 15)),
      ],
    );
  }
}

class _Field extends StatelessWidget {
  final String label;
  final TextEditingController ctrl;
  final IconData? icon;
  final String? hint;
  final TextInputType? type;
  final String? Function(String?)? validator;

  const _Field({
    required this.label,
    required this.ctrl,
    this.icon,
    this.hint,
    this.type,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppText.label),
        const SizedBox(height: 8),
        TextFormField(
          controller: ctrl,
          keyboardType: type,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: icon != null ? Icon(icon, size: 18) : null,
          ),
          validator: validator,
        ),
      ],
    );
  }
}

class _ReadonlyField extends StatelessWidget {
  final String label, value;
  final IconData? icon;

  const _ReadonlyField({required this.label, required this.value, this.icon});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppText.label),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: kGreyLight,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: kGreyBorder),
          ),
          child: Row(
            children: [
              if (icon != null) ...[Icon(icon, size: 18, color: kGrey), const SizedBox(width: 10)],
              Text(value, style: AppText.body.copyWith(color: kGrey)),
            ],
          ),
        ),
      ],
    );
  }
}