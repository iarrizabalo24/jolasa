import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:fluttergame/services/odooservice.dart';
import 'package:fluttergame/services/localdbservice.dart';
import 'package:fluttergame/models/gamescore.dart';

/// Este servicio es el "cerebro" que orquesta los otros dos.
/// Decide cuándo sincronizar y qué hacer.
class SyncService {
  final OdooService _odooService;
  final LocalDbService _localDbService;

  SyncService(this._odooService, this._localDbService);

  bool _isSyncing = false;

  Future<bool> isOnline() async {
    final connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult.contains(ConnectivityResult.mobile) ||
        connectivityResult.contains(ConnectivityResult.wifi)) {
      return true;
    }
    return false;
  }

  /// La función principal de sincronización.
  /// Llamar a esto al iniciar la app y periódicamente.
  Future<void> syncData() async {
    if (_isSyncing) return; // Evitar sincronización múltiple
    if (!await isOnline()) {
      print('Modo Offline. No se puede sincronizar.');
      return;
    }

    _isSyncing = true;
    print('Iniciando sincronización...');

    try {
      // 1. Asegurarse de estar logueado en Odoo
      if (!_odooService.isLogged) {
        await _odooService.login();
      }

      // 2. Sincronizar Puntuaciones (Subir primero)
      // Traer puntuaciones locales pendientes
      final pendingScores = await _localDbService.getPendingSyncScores();
      if (pendingScores.isNotEmpty) {
        print('Subiendo ${pendingScores.length} puntuaciones pendientes...');
        List<int> syncedScoreIds = [];
        for (var score in pendingScores) {
          bool success = await _odooService.submitScore(
            score.userId,
            score.userName,
            score.score,
          );
          if (success) {
            // ¡Importante! El ID local es 'score.id'
            if (score.id != null) {
              syncedScoreIds.add(score.id!);
            }
          }
        }
        // Marcar las puntuaciones subidas como 'synced' en local
        await _localDbService.markScoresAsSynced(syncedScoreIds);
      }

      // 3. Sincronizar Productos (Bajar)
      print('Bajando productos de Odoo...');
      final odooProducts = await _odooService.fetchProducts();
      if (odooProducts.isNotEmpty) {
        await _localDbService.syncProducts(odooProducts);
      }

      // 4. (Opcional) Sincronizar Ranking (Bajar)
      // Podrías guardar el ranking de Odoo en otra tabla local
      // para tener un ranking "Top" incluso offline.
      // final odooRanking = await _odooService.fetchRanking();
      // await _localDbService.syncRanking(odooRanking);

      print('Sincronización completada.');
    } catch (e) {
      print('Error durante la sincronización: $e');
    } finally {
      _isSyncing = false;
    }
  }

  /// Función para guardar una puntuación nueva desde el juego.
  Future<void> postNewScore(int userId, String userName, int score) async {
    final newScore = GameScore(
      userId: userId,
      userName: userName,
      score: score,
      date: DateTime.now(),
      isSynced: false, // Siempre se crea como "no sincronizado"
    );

    // 1. Guardar siempre en local
    await _localDbService.saveScoreLocally(newScore);

    // 2. Intentar subir a Odoo si hay conexión
    if (await isOnline()) {
      print('Intentando subida rápida de puntuación...');
      try {
        if (!_odooService.isLogged) {
          await _odooService.login();
        }
        final success =
        await _odooService.submitScore(userId, userName, score);
        if (success) {
          // Si se sube bien, marcamos la copia local como sincronizada
          // (Necesitaríamos el ID local que se acaba de insertar)
          // Por simplicidad, dejaremos que el próximo `syncData()` lo maneje.
          // O podrías hacer:
          // newScore.isSynced = true;
          // await _localDbService.saveScoreLocally(newScore); // Esto haría un 'replace'

          // Manera más simple: dejar que el syncData() lo solucione
          await syncData(); // Lanzar una sincro en segundo plano
        }
      } catch (e) {
        print('Error en subida rápida. Se sincronizará más tarde.');
      }
    } else {
      print('Puntuación guardada localmente (offline). Se subirá al conectar.');
    }
  }
}