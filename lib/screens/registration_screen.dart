import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../utils/snackbar.dart';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _userCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _obscure1 = true;
  bool _obscure2 = true;

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    final pass = _passCtrl.text.trim();
    final confirm = _confirmCtrl.text.trim();
    if (pass != confirm) {
      showCustomSnackBar(
        context,
        'Pasahitzak ez datoz bat 🔒',
        color: Colors.redAccent.shade100,
        icon: Icons.error_outline,
      );
      return;
    }

    final ok = await AuthService.instance.register(
      _userCtrl.text.trim(),
      pass,
    );

    if (!mounted) return;

    if (ok) {
      showCustomSnackBar(
        context,
        '✅ Eskaera bidali da!\nItxaron administratzailearen onarpena.',
        color: Colors.lightBlue.shade200,
        icon: Icons.info_outline,
      );
      Navigator.of(context).pop();
    } else {
      showCustomSnackBar(
        context,
        'Erabiltzailea existitzen da edo eskaera bidalita dago ⚠️',
        color: Colors.orange.shade200,
        icon: Icons.warning_amber_rounded,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Erregistratu'),
        backgroundColor: cs.primary,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Card(
            elevation: 8,
            margin: const EdgeInsets.all(24),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Sortu kontu berria',
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(color: cs.primary),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),

                    TextFormField(
                      controller: _userCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Erabiltzailea',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      validator: (v) =>
                      v!.isEmpty ? 'Idatzi erabiltzaile izena' : null,
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _passCtrl,
                      obscureText: _obscure1,
                      decoration: InputDecoration(
                        labelText: 'Pasahitza',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscure1
                                ? Icons.visibility
                                : Icons.visibility_off,
                            color: cs.primary,
                          ),
                          onPressed: () =>
                              setState(() => _obscure1 = !_obscure1),
                        ),
                      ),
                      validator: (v) =>
                      v!.isEmpty ? 'Idatzi pasahitza' : null,
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _confirmCtrl,
                      obscureText: _obscure2,
                      decoration: InputDecoration(
                        labelText: 'Pasahitza berriro',
                        prefixIcon:
                        const Icon(Icons.lock_reset_outlined),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscure2
                                ? Icons.visibility
                                : Icons.visibility_off,
                            color: cs.primary,
                          ),
                          onPressed: () =>
                              setState(() => _obscure2 = !_obscure2),
                        ),
                      ),
                      validator: (v) =>
                      v!.isEmpty ? 'Berriro idatzi pasahitza' : null,
                      onFieldSubmitted: (_) =>
                          _register(),
                    ),

                    const SizedBox(height: 24),

                    FilledButton.icon(
                      onPressed: _register,
                      icon: const Icon(Icons.person_add_alt_1),
                      label: const Text('Erregistratu'),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}