import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class EmaitzaScreen extends StatefulWidget {
  final int guztira;
  final int txandak;

  const EmaitzaScreen({
    super.key,
    required this.guztira,
    required this.txandak,
  });

  @override
  State<EmaitzaScreen> createState() => _EmaitzaScreenState();
}

class _EmaitzaScreenState extends State<EmaitzaScreen> {
  @override
  void initState() {
    super.initState();
    try {
      AuthService.instance.saveScore(widget.guztira);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final maxPuntuak = widget.txandak * 120;
    final ehunekoa = (widget.guztira / maxPuntuak * 100).round();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Emaitzak'),
        backgroundColor: cs.primary,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [cs.primary, cs.secondary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  ehunekoa >= 80
                      ? Icons.emoji_events
                      : ehunekoa >= 50
                      ? Icons.celebration
                      : Icons.sentiment_satisfied,
                  size: 72,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Zure puntuazioa',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Text(
                '${widget.guztira} / $maxPuntuak',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: cs.primary,
                ),
              ),
              Text(
                '$ehunekoa%',
                style: TextStyle(
                  fontSize: 18,
                  color: cs.onSurface.withOpacity(0.7),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 24),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    ehunekoa >= 80
                        ? 'Bikain! Prezioen aditua zara! 🎯'
                        : ehunekoa >= 50
                        ? 'Ongi! Jarraitu horrela! 👍'
                        : 'Lanean jarraitu beharra dago! Ez etsi! 💪',
                    style: const TextStyle(fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Padding(
                  padding:
                  EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  child: Text('Itzuli menu nagusira'),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}