import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'menu_screen.dart';
import 'admin_screen.dart';
import 'registration_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _userCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  String? _error;
  bool _obscure = true;

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    final username = _userCtrl.text.trim();
    final password = _passCtrl.text.trim();

    final ok = await AuthService.instance.login(username, password);

    if (!ok) {
      final exists = await AuthService.instance.userExists(username);
      final pending = await AuthService.instance.pendingExists(username);

      setState(() {
        if (pending) {
          _error =
          'Zure kontua oraindik ez du administratzaileak onartu.\nSaiatu geroago berriro.';
        } else if (exists) {
          _error = 'Erabiltzaile edo pasahitza okerra';
        } else {
          _error =
          'Ez dago konturik erabiltzaile honekin.\nEgin klik "Erregistratu" botoian eskaera bat bidaltzeko.';
        }
      });
      return;
    }

    final u = AuthService.instance.currentUser!;
    if (!mounted) return;

    if (u.isAdmin) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const AdminScreen()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MenuScreen()),
      );
    }
  }

  void _openRegistration() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const RegistrationScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Card(
            elevation: 8,
            margin: const EdgeInsets.all(24),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Sartu zure kontuan',
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(color: cs.primary),
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _userCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Erabiltzailea',
                        prefixIcon: Icon(Icons.person),
                      ),
                      validator: (v) =>
                      v!.isEmpty ? 'Idatzi erabiltzailea' : null,
                    ),
                    const SizedBox(height: 12),

                    TextFormField(
                      controller: _passCtrl,
                      obscureText: _obscure,
                      decoration: InputDecoration(
                        labelText: 'Pasahitza',
                        prefixIcon: const Icon(Icons.lock),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscure
                                ? Icons.visibility
                                : Icons.visibility_off,
                          ),
                          onPressed: () =>
                              setState(() => _obscure = !_obscure),
                        ),
                      ),
                      validator: (v) =>
                      v!.isEmpty ? 'Idatzi pasahitza' : null,
                      onFieldSubmitted: (_) => _login(),
                    ),

                    if (_error != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        _error!,
                        style: TextStyle(
                          color: _error!.contains('✅')
                              ? Colors.green
                              : Colors.red,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],

                    const SizedBox(height: 18),

                    FilledButton.icon(
                      onPressed: _login,
                      icon: const Icon(Icons.login),
                      label: const Text('Hasi saioa'),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(double.infinity, 48),
                      ),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: _openRegistration,
                      icon: const Icon(Icons.person_add),
                      label: const Text('Erregistratu'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 48),
                      ),
                    ),
                    const SizedBox(height: 8),
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