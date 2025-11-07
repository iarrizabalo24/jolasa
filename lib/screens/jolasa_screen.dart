import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/localdbservice.dart';
import '../services/local_scores.dart';
import '../services/auth_service.dart';
import '../models/product.dart';
// import '../models/gamescore.dart'; // <-- Eliminado: Este era uno de los 3 "errores" (import innecesario)
import '../models/difficulty.dart';
import 'emaitza_screen.dart';
import '../widgets/prezioasmatu_input.dart';

class JolasaScreen extends StatefulWidget {
  final Difficulty zailtasuna;
  const JolasaScreen({super.key, required this.zailtasuna});

  @override
  State<JolasaScreen> createState() => _JolasaScreenState();
}

class _JolasaScreenState extends State<JolasaScreen> {
  bool _kargatzen = true;
  int _txanda = 0;
  int _puntuak = 0;
  final int _guztiraTxandak = 10;
  // Este Set se usará para no repetir productos
  final _erabilitakoIdak = <int>{};
  final _sarreraCtrl = TextEditingController();
  Product? _oraingoa;
  String? _feedback;

  @override
  void initState() {
    super.initState();
    _hurrengoaKargatu();
  }

  Future<void> _hurrengoaKargatu() async {
    setState(() {
      _kargatzen = true;
      _feedback = null;
      _sarreraCtrl.text = '';
    });

    final productos = await context.read<LocalDbService>().getLocalProducts();

// Filtramos los que aún no se han usado
    final disponibles = productos
        .where((prod) => !_erabilitakoIdak.contains(prod.id))
        .toList();

    if (disponibles.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Ez dago produkturik eskuragarri. (Edo guztiak erabili dira)')),
      );
      Navigator.of(context).pop();
      return;
    }

// Elegimos el siguiente producto (puedes cambiar esto a aleatorio si quieres)
    final p = disponibles.first;

// Añadir ID al Set
    _erabilitakoIdak.add(p.id);

    setState(() {
      _oraingoa = p;
      _txanda += 1;
      _kargatzen = false;
    });

  }

  int _kalkulatuPuntuak(double asmaketa, double benetakoa) {
    final rel = (asmaketa - benetakoa).abs() / max(3.0, benetakoa);
    final k = switch (widget.zailtasuna) {
      Difficulty.erraza => 1.2,
      Difficulty.ertaina => 1.6,
      Difficulty.zaila => 2.1,
    };
    final score = (100 * exp(-k * rel)).clamp(0, 100).round();
    final bonus = (asmaketa - benetakoa).abs() < 0.01 ? 20 : 0;
    return (score + bonus).clamp(0, 120);
  }

  Future<void> _bidali() async {
    if (_oraingoa == null) return;
    final testua = _sarreraCtrl.text.replaceAll(',', '.').trim();
    final balioa = double.tryParse(testua);
    if (balioa == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Jarri balio egoki bat (€)')),
      );
      return;
    }

    final puntu = _kalkulatuPuntuak(balioa, _oraingoa!.prezioa);
    setState(() {
      _puntuak += puntu;

      _feedback = balioa == _oraingoa!.prezioa
          ? 'ZORIONAK! ZUZENA 🎉 +${puntu} puntu.'
          : (balioa > _oraingoa!.prezioa
          ? 'Garestiegia 💸 +${puntu} puntu.\nBenetako prezioa: ${_oraingoa!.prezioa.toStringAsFixed(2)}€'
          : 'Merkeegia 💶 +${puntu} puntu.\nBenetako prezioa: ${_oraingoa!.prezioa.toStringAsFixed(2)}€');
    });

    await Future.delayed(const Duration(seconds: 4));

    if (_txanda >= _guztiraTxandak) {
      final u = AuthService.instance.currentUser;
      final username = u?.username ?? 'anon';

      // Lógica actual: Guardar Puntuación MÁXIMA
      final maxOld = await LocalScores.getHighScore(username) ?? 0;
      if (_puntuak > maxOld) {
        await LocalScores.setHighScore(username, _puntuak);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('🏆 Puntuazio berria gordeta: $_puntuak')),
          );
        }
      }

      // (Se eliminó el bloque comentado de GameScore para mayor claridad)

      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => EmaitzaScreen(
            guztira: _puntuak,
            txandak: _guztiraTxandak,
          ),
        ),
      );
    } else {
      _hurrengoaKargatu();
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = _oraingoa;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('ASMATU PREZIOA'),
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: _kargatzen
            ? const Center(child: CircularProgressIndicator())
            : Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                _Txip(text: 'Produktua: $_txanda/$_guztiraTxandak'),
                const SizedBox(width: 8),
                _Txip(text: 'Puntuak: $_puntuak'),
                const Spacer(),
                _Txip(
                  text: switch (widget.zailtasuna) {
                    Difficulty.erraza => 'Erraza',
                    Difficulty.ertaina => 'Ertaina',
                    Difficulty.zaila => 'Zaila'
                  },
                  kolorea: switch (widget.zailtasuna) {
                    Difficulty.erraza => const Color(0xFF4CAF50),
                    Difficulty.ertaina => const Color(0xFFFF9800),
                    Difficulty.zaila => const Color(0xFFF44336),
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),
            Card(
              elevation: 8,
              shadowColor: Colors.black.withOpacity(0.2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      cs.primaryContainer,
                      cs.secondaryContainer.withOpacity(0.7),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Zenbat balio du?',
                        style: Theme.of(context)
                            .textTheme
                            .labelLarge
                            ?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: cs.onPrimaryContainer,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        p!.izena,
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: cs.onPrimaryContainer,
                          fontSize: 24,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Asmatu produktu honen prezioa!',
                        style: TextStyle(
                          fontSize: 16,
                          color: cs.onPrimaryContainer.withOpacity(0.8),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      if (_feedback != null) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: cs.primary,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: cs.primary.withOpacity(0.3),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Text(
                            _feedback!,
                            style: Theme.of(context)
                                .textTheme
                                .bodyLarge
                                ?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 18,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            PrezioaInput(
              onSubmit: (balioa) {
                _sarreraCtrl.text = balioa.toString();
                _bidali();
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _Txip extends StatelessWidget {
  final String text;
  final Color? kolorea;

  const _Txip({required this.text, this.kolorea});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: kolorea ?? cs.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(999),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        text,
        style: TextStyle(
          color: kolorea != null ? Colors.white : cs.onSurface,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}