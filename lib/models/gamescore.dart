/// Modelo para las puntuaciones.
class GameScore {
  final int? id; // ID local de Sqflite (autoincremental)
  final int userId; // ID del usuario de Odoo (res.partner)
  final String userName; // Para mostrar en el ranking local
  final int score;
  final DateTime date;
  bool isSynced; // <-- La clave para la sincronización

  GameScore({
    this.id,
    required this.userId,
    required this.userName,
    required this.score,
    required this.date,
    this.isSynced = false,
  });

  // Método para convertir a mapa para Sqflite
  // CAMBIO: Renombrado de 'toSqfliteMap' a 'toMap'
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'user_name': userName,
      'score': score,
      'date': date.toIso8601String(),
      'is_synced': isSynced ? 1 : 0, // Sqflite usa 0 y 1 para booleanos
    };
  }

  // Factory para crear desde el mapa de Sqflite
  // CAMBIO: Renombrado de 'fromSqflite' a 'fromMap'
  factory GameScore.fromMap(Map<String, dynamic> map) {
    return GameScore(
      id: map['id'] as int,
      userId: map['user_id'] as int,
      userName: map['user_name'] as String,
      score: map['score'] as int,
      date: DateTime.parse(map['date'] as String),
      isSynced: map['is_synced'] == 1,
    );
  }
}