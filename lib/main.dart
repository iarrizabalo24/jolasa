import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fluttergame/services/odooservice.dart';
import 'package:fluttergame/services/localdbservice.dart';
import 'package:fluttergame/services/syncservice.dart';
// Importar las pantallas del menú principal, juego, ranking, etc.
// import 'package:erronka_jokoa/screens/menu_screen.dart';

void main() {
  // Asegurarse de que Flutter está inicializado
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializar los servicios
  final odooService = OdooService();
  final localDbService = LocalDbService();
  final syncService = SyncService(odooService, localDbService);

  runApp(
    MultiProvider(
      providers: [
        // Proveer los servicios a toda la app
        Provider.value(value: odooService),
        Provider.value(value: localDbService),
        Provider.value(value: syncService),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Erronka Jokoa',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      debugShowCheckedModeBanner: false,
      // Empezar con una pantalla de carga que haga la primera sincronización
      home: const SplashScreen(),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      // 1. Intentar la sincronización de datos
      // 'context.read' funciona en initState
      final syncService = context.read<SyncService>();
      await syncService.syncData();

    } catch (e) {
      print("Error en sincronización inicial: $e");
      // No importa si falla, el juego debe poder continuar offline
      // con los datos que *ya tenga* en Sqflite.
    } finally {
      // 2. Cuando termine (bien o mal), navegar al menú principal
      // Usar 'mounted' para evitar errores si el widget se destruye
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (ctx) => const MainMenuScreen()), // Deben crear esta pantalla
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Aquí iría el logo (requisito de multimedia)
            // Asegúrense de añadir 'assets/images/logo.png' al pubspec.yaml
            Image.asset(
              'assets/images/logo.png',
              width: 150,
              // Usar un placeholder si la imagen no carga
              errorBuilder: (context, error, stackTrace) =>
              const Icon(Icons.games, size: 100),
            ),
            const SizedBox(height: 30),
            const CircularProgressIndicator(),
            const SizedBox(height: 20),
            const Text('Sincronizando datos...'),
          ],
        ),
      ),
    );
  }
}

// --- PANTALLA FICTICIA ---
// Creen sus pantallas (menu, juego, ranking) basadas en esta estructura
class MainMenuScreen extends StatelessWidget {
  const MainMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Prezioa Asmatu'),
        actions: [
          // Botón para forzar sincronización
          IconButton(
            icon: const Icon(Icons.sync),
            onPressed: () async {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Sincronizando...')),
              );
              await context.read<SyncService>().syncData();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('¡Sincronización completada!')),
              );
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                // Navegar a 'JolasaScreen' (de ealberdi)
                // Esta pantalla ahora debe usar `context.read<LocalDbService>().getLocalProducts()`
                // para obtener los productos del juego.
              },
              child: const Text('Jolastu'),
            ),
            ElevatedButton(
              onPressed: () {
                // Navegar a 'RankingPantaila' (de iarrizabalo)
                // Esta pantalla debe intentar cargar con `OdooService`
                // y si falla (offline), cargar con `LocalDbService`.
              },
              child: const Text('Ranking'),
            ),
          ],
        ),
      ),
    );
  }
}