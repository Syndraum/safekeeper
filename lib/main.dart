import 'package:flutter/material.dart';
import 'screens/upload_screen.dart';
import 'screens/document_list_screen.dart';
import 'services/encryption_service.dart';

void main() async {
  // Ensure Flutter bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize encryption service (generates RSA keys if not present)
  final encryptionService = EncryptionService();
  await encryptionService.initialize();
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'App de Gestion de Documents',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color.fromARGB(255, 36, 77, 124)),
      ),
      // Définit les routes pour naviguer entre écrans
      routes: {
        '/': (context) =>
            const MyHomePage(title: 'Accueil - Gestion de Documents'),
        '/upload': (context) => UploadScreen(),
        '/list': (context) => DocumentListScreen(),
      },
      // home: const MyHomePage(title: 'Flutter Demo Home Page'),  // Supprime ou commente cette ligne, car on utilise routes
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Vous avez appuyé sur le bouton tant de fois :'),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 20), // Espacement
            // Boutons pour naviguer vers les nouvelles fonctionnalités
            ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, '/upload'),
              child: const Text('Uploader un document'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, '/list'),
              child: const Text('Voir la liste des documents'),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }
}
