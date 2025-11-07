import 'package:odoo_rpc/odoo_rpc.dart';
import 'package:fluttergame/models/product.dart';

/// Gestiona TODA la comunicación con la API RPC de Odoo.
/// No más lógica de Odoo fuera de este archivo.
class OdooService {
  late OdooClient _client;
  OdooSession? _session;

  // Configuración de Odoo (¡Nunca hardcodear credenciales en producción!)
  // En un proyecto real, esto estaría en un formulario de login.
  final String _serverUrl = 'https://localhost';
  final String _dbName = 'izarraitz';
  final String _username = 'odoo'; // o el usuario que sea
  final String _password = 'odoo'; // ¡Mala práctica! Solo para pruebas.

  OdooService() {
    _client = OdooClient(_serverUrl);
  }

  Future<void> login() async {
    try {
      final session = await _client.authenticate(
        _dbName,
        _username,
        _password,
      );
      _session = session;
      print('Login en Odoo exitoso! Sesión: ${session.id}');
    } catch (e) {
      print('Error en login de Odoo: $e');
      _session = null;
      rethrow; // Lanzar el error para que la UI lo sepa
    }
  }

  bool get isLogged => _session != null;

  /// Trae los productos de Odoo.
  /// Basado en 'Consultas SQL.pdf' (product.template).
  Future<List<Product>> fetchProducts() async {
    if (!isLogged) await login();

    try {
      final response = await _client.callKw({
        'model': 'product.template',
        'method': 'search_read',
        'args': [
          [
            ['sale_ok', '=', true]
          ], // Ejemplo: traer solo productos que se venden
        ],
        'kwargs': {
          'fields': ['id', 'name', 'list_price'],
        },
      });

      if (response is List) {
        return response
            .map((json) => Product.fromOdoo(json as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      print('Error fetching Odoo products: $e');
      return [];
    }
  }

  /// Trae el ranking de Odoo.
  /// Basado en 'Consultas SQL.pdf' (jolas_puntuak).
  Future<List<Map<String, dynamic>>> fetchRanking() async {
    if (!isLogged) await login();

    try {
      final response = await _client.callKw({
        'model': 'jolas.puntuak', // El modelo que creaste en Odoo
        'method': 'search_read',
        'args': [
          [] // Sin filtros, traer todos
        ],
        'kwargs': {
          'fields': ['jokalari_id', 'puntuak'], // Asumiendo estos campos
          'order': 'puntuak DESC',
          'limit': 20,
        },
      });
      // Esto devolverá algo como [{'jokalari_id': [3, 'Iarrizabalo'], 'puntuak': 100}, ...]
      // Tendrás que procesarlo
      if (response is List) {
        return List<Map<String, dynamic>>.from(response);
      }
      return [];
    } catch (e) {
      print('Error fetching Odoo ranking: $e');
      return [];
    }
  }

  /// Sube una nueva puntuación a Odoo.
  Future<bool> submitScore(int userId, String userName, int score) async {
    if (!isLogged) await login();

    try {
      // Esto asume que 'jolas.puntuak' tiene un campo 'jokalari_id' (Many2one a res.partner)
      // y 'puntuak' (Integer).
      // El código de 'iarrizabalo' ('Codigo iarrizabalo.pdf', pág. 19)
      // tiene una lógica 'INSERT ... ON CONFLICT', que es SQL directo.
      // En RPC, sería más una búsqueda y luego 'write' o 'create'.

      // 1. Buscar si el usuario ya tiene puntuación
      final existingScore = await _client.callKw({
        'model': 'jolas.puntuak',
        'method': 'search_read',
        'args': [
          [
            ['jokalari_id', '=', userId]
          ]
        ],
        'kwargs': {
          'fields': ['puntuak'],
          'limit': 1,
        },
      });

      if (existingScore is List && existingScore.isNotEmpty) {
        // Usuario encontrado, actualizar si la puntuación es MEJOR
        int oldScore = (existingScore[0]['puntuak'] as num?)?.toInt() ?? 0;
        if (score > oldScore) {
          int scoreId = existingScore[0]['id'] as int;
          await _client.callKw({
            'model': 'jolas.puntuak',
            'method': 'write',
            'args': [
              [scoreId], // IDs a actualizar
              {'puntuak': score} // Valores a poner
            ],
          });
          print('Puntuación actualizada en Odoo para $userName');
        }
      } else {
        // Usuario no encontrado, crear nueva entrada
        await _client.callKw({
          'model': 'jolas.puntuak',
          'method': 'create',
          'args': [
            {
              'jokalari_id': userId,
              'puntuak': score,
              // 'name': userName // Puede que Odoo lo pida
            }
          ],
        });
        print('Puntuación nueva creada en Odoo para $userName');
      }
      return true;
    } catch (e) {
      print('Error submitting score to Odoo: $e');
      return false;
    }
  }
}