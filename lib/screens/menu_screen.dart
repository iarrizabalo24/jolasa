import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'admin_screen.dart';
import 'jolasa_screen.dart';
import 'ranking_screen.dart';
import '../services/auth_service.dart';
import '../services/local_scores.dart';
import 'login_screen.dart';
import '../models/difficulty.dart';

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});
  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  int? _puntuazioGorena;

  @override
  void initState() {
    super.initState();
    _kargatu();
  }

  Future<void> _kargatu() async {
    final u = AuthService.instance.currentUser;
    if (u == null) return;

    final username = u.username;
    final maxUser = await LocalScores.getHighScore(username);

    setState(() {
      _puntuazioGorena = maxUser;
    });
  }

  void _hasi(Difficulty zailtasuna) async {
    await Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => JolasaScreen(zailtasuna: zailtasuna),
    ));
    _kargatu();
  }

  Future<void> _adminera() async {
    await Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const AdminScreen()));
    _kargatu();
  }

  void _erakutsiInformazioa() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.school, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 8),
            const Text('Nola jokatu'),
          ],
        ),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '10 produkturen prezioa asmatzea da helburua. '
                    'Benetako preziotik zenbat eta hurbilago, orduan eta puntu gehiago lortuko dituzu.\n\n'
                    'Puntuazio sistema:\n',
                style: TextStyle(fontSize: 16, height: 1.5),
              ),
              SizedBox(height: 8),
              _InformazioElementua(
                ikonoa: Icons.sentiment_very_satisfied,
                izena: 'Erraza',
                deskribapena: 'Puntuazio altuagoa errore gehagorekin',
                kolorea: Color(0xFF4CAF50),
              ),
              SizedBox(height: 8),
              _InformazioElementua(
                ikonoa: Icons.speed,
                izena: 'Ertaina',
                deskribapena: 'Orekatua, zailtasun gomendatua',
                kolorea: Color(0xFF2196F3),
              ),
              SizedBox(height: 8),
              _InformazioElementua(
                ikonoa: Icons.whatshot,
                izena: 'Zaila',
                deskribapena:
                'Zehaztasun handia behar da puntuazio altua lortzeko',
                kolorea: Color(0xFFF44336),
              ),
              SizedBox(height: 16),
              Text(
                'Zenbat asma ditzakezu?',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Ulertuta'),
          ),
        ],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  Future<void> _irten() async {
    await AuthService.instance.logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
          (r) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isAdmin = AuthService.instance.currentUser?.isAdmin == true;

    return Scaffold(
      appBar: AppBar(
        title: const Text('ASMATU PRODUKTUEN PREZIOAK'),
        actions: [
          IconButton(
            tooltip: 'Saioa itxi',
            icon: const Icon(Icons.logout),
            onPressed: _irten,
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxHeight: constraints.maxHeight),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 4),
                    _GoiburuBanner(puntuazioGorena: _puntuazioGorena),
                    const SizedBox(height: 16),

                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.auto_awesome, color: cs.primary),
                                const SizedBox(width: 8),
                                Text(
                                  'Aukeratu zailtasuna',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleLarge
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            _ZailtasunAukera(
                              ikonoa: Icons.sentiment_very_satisfied,
                              izena: 'ERRAZA',
                              deskribapena: 'Errore gehiago onartzen dira',
                              kolorea: const Color(0xFF4CAF50),
                              onPressed: () => _hasi(Difficulty.erraza),
                            ),
                            const SizedBox(height: 8),
                            _ZailtasunAukera(
                              ikonoa: Icons.speed,
                              izena: 'ERTAINA',
                              deskribapena: 'Orekatua, zailtasun gomendatua',
                              kolorea: const Color(0xFF2196F3),
                              onPressed: () => _hasi(Difficulty.ertaina),
                            ),
                            const SizedBox(height: 8),
                            _ZailtasunAukera(
                              ikonoa: Icons.whatshot,
                              izena: 'ZAILA',
                              deskribapena: 'Zehaztasun handia behar da',
                              kolorea: const Color(0xFFF44336),
                              onPressed: () => _hasi(Difficulty.zaila),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // --- Admin (solo si es admin) ---
                    if (isAdmin)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: _BotoiTxikia(
                          ikonoa: Icons.admin_panel_settings,
                          izena: 'KUDEAKETA',
                          azpizena: 'Administrazioa',
                          kolorea: const Color(0xFF4CAF50),
                          onPressed: _adminera,
                        ),
                      ),

                    const SizedBox(height: 16),

                    // --- Ranking + Nola Jokatu ---
                    Row(
                      children: [
                        Expanded(
                          child: _BotoiTxikia(
                            ikonoa: Icons.emoji_events,
                            izena: 'RANKING',
                            azpizena: 'Sailkapena',
                            kolorea: const Color(0xFFFF9800),
                            onPressed: () async {
                              await Navigator.of(context).push(
                                MaterialPageRoute(
                                    builder: (_) => const RankingScreen()),
                              );
                              _kargatu();
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _BotoiTxikia(
                            ikonoa: Icons.info_outline,
                            izena: 'NOLA JOKATU',
                            azpizena: 'Informazioa',
                            kolorea: const Color(0xFF2196F3),
                            onPressed: _erakutsiInformazioa,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _BotoiTxikia extends StatelessWidget {
  final IconData ikonoa;
  final String izena;
  final String azpizena;
  final Color kolorea;
  final VoidCallback onPressed;

  const _BotoiTxikia({
    required this.ikonoa,
    required this.izena,
    required this.azpizena,
    required this.kolorea,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                kolorea.withOpacity(0.12),
                kolorea.withOpacity(0.04),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: kolorea.withOpacity(0.25)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: kolorea.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(ikonoa, color: kolorea, size: 24),
              ),
              const SizedBox(height: 8),
              Text(
                izena,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: kolorea,
                ),
                textAlign: TextAlign.center,
              ),
              Text(
                azpizena,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InformazioElementua extends StatelessWidget {
  final IconData ikonoa;
  final String izena;
  final String deskribapena;
  final Color kolorea;

  const _InformazioElementua({
    required this.ikonoa,
    required this.izena,
    required this.deskribapena,
    required this.kolorea,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: kolorea.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(12),
        color: kolorea.withOpacity(0.05),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: kolorea.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(ikonoa, color: kolorea, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  izena,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: kolorea, fontWeight: FontWeight.w600),
                ),
                Text(deskribapena,
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: Colors.grey[700])),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GoiburuBanner extends StatelessWidget {
  final int? puntuazioGorena;
  const _GoiburuBanner({required this.puntuazioGorena});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [cs.primary, cs.primaryContainer],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: cs.primary.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child:
            const Icon(Icons.shopping_bag, size: 40, color: Colors.white),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('ONGI ETORRI!',
                    style: t.headlineMedium?.copyWith(
                        color: Colors.white, fontWeight: FontWeight.w800)),
                Text('PUNTUAZIO GORENA:',
                    style: t.bodyLarge?.copyWith(color: Colors.white70)),
                Text('${puntuazioGorena ?? 0} puntu',
                    style: t.headlineSmall?.copyWith(
                        color: Colors.white, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ZailtasunAukera extends StatelessWidget {
  final IconData ikonoa;
  final String izena;
  final String deskribapena;
  final Color kolorea;
  final VoidCallback onPressed;

  const _ZailtasunAukera({
    required this.ikonoa,
    required this.izena,
    required this.deskribapena,
    required this.kolorea,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: kolorea.withOpacity(0.3)),
            borderRadius: BorderRadius.circular(16),
            color: kolorea.withOpacity(0.05),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: kolorea.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(ikonoa, color: kolorea),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(izena,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: kolorea, fontWeight: FontWeight.w600)),
                    Text(deskribapena,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[700])),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios_rounded,
                  color: kolorea, size: 16),
            ],
          ),
        ),
      ),
    );
  }
}