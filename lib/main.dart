import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart'; // Importa go_router

// Inserisci qui le tue credenziali Supabase
const supabaseUrl = 'https://vicfhzumltbfqyzsxawb.supabase.co'; // Sostituisci con il Project URL
const supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZpY2ZoenVtbHRiZnF5enN4YXdiIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTMyNzM3OTMsImV4cCI6MjA2ODg0OTc5M30.seNdu_v0Bh0xpCHyVPzcK0gjbV-vBj2-GjGfpHAwKCw'; // Sostituisci con la tua anon key

Future<void> main() async {
  // Assicurati che il binding Flutter sia inizializzato prima di chiamare i metodi nativi
  WidgetsFlutterBinding.ensureInitialized();

  // Inizializza Supabase
  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
    debug: true, // Imposta a false in produzione
  );
  runApp(const MyApp());
}

// Puoi accedere all'istanza di Supabase in qualsiasi punto della tua app così:
final supabase = Supabase.instance.client;

// Definiamo un router semplice per l'esempio di navigazione
final GoRouter _router = GoRouter(
  routes: <RouteBase>[
    GoRoute(
      path: '/',
      builder: (BuildContext context, GoRouterState state) {
        // Logica per decidere quale pagina mostrare all'avvio
        // Se l'utente è loggato, mostra la Dashboard, altrimenti la pagina di Login
        return supabase.auth.currentUser == null ? const LoginPage() : const DashboardPage();
      },
    ),
    GoRoute(
      path: '/login',
      builder: (BuildContext context, GoRouterState state) {
        return const LoginPage();
      },
    ),
    GoRoute(
      path: '/signup',
      builder: (BuildContext context, GoRouterState state) {
        return const SignUpPage();
      },
    ),
    GoRoute(
      path: '/dashboard',
      builder: (BuildContext context, GoRouterState state) {
        return const DashboardPage();
      },
    ),
    // Aggiungi un percorso per il callback di autenticazione, se necessario per il tuo provider
    GoRoute(
      path: '/login-callback', // Deve corrispondere a authCallbackUrlHostname
      builder: (BuildContext context, GoRouterState state) {
        // Questa pagina potrebbe gestire il reindirizzamento dopo un login esterno
        // In un'app reale, potresti reindirizzare l'utente alla dashboard
        return const LoginPage(); // O una schermata di caricamento che reindirizza
      },
    ),
  ],
  redirect: (BuildContext context, GoRouterState state) {
    final loggedIn = supabase.auth.currentUser != null;
    final goingToLogin = state.fullPath == '/login' || state.fullPath == '/signup';

    // Se non loggato e non si sta andando alla pagina di login, reindirizza al login
    if (!loggedIn && !goingToLogin) {
      return '/login';
    }
    // Se loggato e si sta andando alla pagina di login, reindirizza alla dashboard
    if (loggedIn && goingToLogin) {
      return '/dashboard';
    }
    // Nessun reindirizzamento necessario
    return null;
  },
  // Ascolta i cambiamenti di autenticazione per aggiornare il router
  refreshListenable: GoRouterRefreshStream(supabase.auth.onAuthStateChange),
);


class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Athena Running Coach',
      theme: ThemeData.dark().copyWith(
        primaryColor: Colors.green,
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            foregroundColor: Colors.white, backgroundColor: Colors.green,
          ),
        ),
      ),
      routerConfig: _router, // Usa il router configurato
    );
  }
}

// Helper per aggiornare GoRouter quando lo stato di autenticazione cambia
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<AuthState> stream) {
    notifyListeners(); // Notifica immediatamente lo stato iniziale
    _subscription = stream.asBroadcastStream().listen(
          (event) => notifyListeners(),
    );
  }

  late final StreamSubscription<AuthState> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}


// --- Pagine placeholder ---
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    try {
      await supabase.auth.signInWithPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      if (mounted) context.go('/dashboard'); // Naviga alla dashboard dopo il login
    } on AuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('An unexpected error occurred: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Email'),
              keyboardType: TextInputType.emailAddress,
            ),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _signIn,
              child: const Text('Accedi'),
            ),
            TextButton(
              onPressed: () => context.go('/signup'),
              child: const Text('Non hai un account? Registrati'),
            ),
          ],
        ),
      ),
    );
  }
}

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signUp() async {
    try {
      await supabase.auth.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Registrazione riuscita! Controlla la tua email per la verifica.')),
        );
        context.go('/login'); // Reindirizza al login dopo la registrazione
      }
    } on AuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('An unexpected error occurred: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Registrati')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Email'),
              keyboardType: TextInputType.emailAddress,
            ),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _signUp,
              child: const Text('Registrati'),
            ),
            TextButton(
              onPressed: () => context.go('/login'),
              child: const Text('Hai già un account? Accedi'),
            ),
          ],
        ),
      ),
    );
  }
}

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  Future<void> _signOut(BuildContext context) async {
    try {
      await supabase.auth.signOut();
      if (context.mounted) context.go('/login'); // Reindirizza al login dopo il logout
    } on AuthException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('An unexpected error occurred: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = supabase.auth.currentUser;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _signOut(context),
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Benvenuto, ${user?.email ?? 'Utente'}!'),
            const SizedBox(height: 20),
            // Qui potrai aggiungere i contenuti della tua dashboard
            const Text('Questa è la tua dashboard principale.'),
          ],
        ),
      ),
    );
  }
}