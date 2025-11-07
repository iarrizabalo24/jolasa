import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'package:intl/intl.dart';

class RankingScreen extends StatelessWidget {
  const RankingScreen({super.key});

  Color _colorForPosition(int index) {
    switch (index) {
      case 0:
        return const Color(0xFFFFD700);
      case 1:
        return const Color(0xFFC0C0C0);
      case 2:
        return const Color(0xFFCD7F32);
      default:
        return Colors.blueGrey.shade100;
    }
  }

  IconData _iconForPosition(int index) {
    switch (index) {
      case 0:
        return Icons.emoji_events;
      case 1:
        return Icons.military_tech;
      case 2:
        return Icons.star;
      default:
        return Icons.person;
    }
  }

  String _formatDate(int millis) {
    final date = DateTime.fromMillisecondsSinceEpoch(millis);
    return DateFormat('yyyy/MM/dd HH:mm').format(date);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sailkapena'),
        backgroundColor: cs.primary,
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder(
        future: AuthService.instance.getRanking(),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snap.data as List<ScoreEntry>;
          if (data.isEmpty) {
            return const Center(
              child: Text(
                'Oraindik ez dago emaitzarik',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          final topUser = data.first;

          return Column(
            children: [
              Container(
                margin:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                padding: const EdgeInsets.all(20),
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
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 35,
                      backgroundColor: Colors.white.withOpacity(0.2),
                      child: const Icon(Icons.emoji_events,
                          color: Colors.amber, size: 40),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('🥇 Lehen postua',
                              style: t.bodyMedium?.copyWith(
                                  color: Colors.white70,
                                  fontWeight: FontWeight.w500)),
                          Text(
                            topUser.username,
                            style: t.headlineSmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            '${topUser.bestScore} puntu',
                            style: t.titleMedium?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Azken eguneraketa: ${_formatDate(topUser.updatedAtMillis)}',
                            style: t.bodySmall?.copyWith(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: data.length,
                  itemBuilder: (ctx, i) {
                    final e = data[i];
                    final isTop3 = i < 3;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOut,
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 5,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: _colorForPosition(i),
                          child: Icon(
                            _iconForPosition(i),
                            color: i < 3 ? Colors.white : cs.primary,
                          ),
                        ),
                        title: Text(
                          e.username,
                          style: t.titleMedium?.copyWith(
                              fontWeight:
                              isTop3 ? FontWeight.bold : FontWeight.w500,
                              color: isTop3
                                  ? cs.primary
                                  : Colors.grey.shade800),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Gorena: ${e.bestScore}  |  Azkena: ${e.lastScore}',
                              style: t.bodySmall?.copyWith(
                                color: Colors.grey.shade600,
                              ),
                            ),
                            Text(
                              'Azken eguneraketa: ${_formatDate(e.updatedAtMillis)}',
                              style: t.bodySmall?.copyWith(
                                color: Colors.grey.shade500,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                        trailing: Text(
                          '#${i + 1}',
                          style: t.titleSmall?.copyWith(
                            color: cs.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}