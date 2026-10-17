import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load();
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );
  runApp(const PssApp());
}

// Token desain Prestige
class PssColors {
  static const bg = Color(0xFF0C221C);
  static const bgDeep = Color(0xFF06100E);
  static const surface = Color(0x0FFFFFFF); // kaca 6%
  static const line = Color(0x1FFFFFFF); // tepi 12%
  static const text = Color(0xFFF2F7F1);
  static const muted = Color(0xFF9DB3AD);
  static const green = Color(0xFF77AC43);
  static const lime = Color(0xFFE0F550);
  static const warn = Color(0xFFF2B134);
  static const danger = Color(0xFFF26A5B);
}

class PssApp extends StatelessWidget {
  const PssApp({super.key});

  @override
  Widget build(BuildContext context) {
    final base = ThemeData.dark(useMaterial3: true);
    return MaterialApp(
      title: 'PSS App',
      theme: base.copyWith(
        scaffoldBackgroundColor: PssColors.bg,
        colorScheme: base.colorScheme.copyWith(
          primary: PssColors.lime,
          surface: PssColors.bg,
        ),
        textTheme: GoogleFonts.plusJakartaSansTextTheme(base.textTheme)
            .apply(bodyColor: PssColors.text),
      ),
      home: const Gate(),
    );
  }
}

// Menentukan layar: belum login -> Login, sudah -> Home
class Gate extends StatelessWidget {
  const Gate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snap) {
        final session = Supabase.instance.client.auth.currentSession;
        return session == null ? const LoginPage() : const HomePage();
      },
    );
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final email = TextEditingController(text: 'andi@test.id');
  final pass = TextEditingController();
  String? error;

  Future<void> masuk() async {
    try {
      await Supabase.instance.client.auth
          .signInWithPassword(email: email.text, password: pass.text);
    } on AuthException catch (e) {
      setState(() => error = e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'PSS App',
              style: GoogleFonts.unbounded(
                fontSize: 28,
                fontWeight: FontWeight.w600,
                color: PssColors.lime,
              ),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: email,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            TextField(
              controller: pass,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Password'),
            ),
            const SizedBox(height: 16),
            if (error != null)
              Text(error!, style: const TextStyle(color: PssColors.danger)),
            FilledButton(onPressed: masuk, child: const Text('Masuk')),
          ],
        ),
      ),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final client = Supabase.instance.client;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Jendela penjualan'),
        actions: [
          IconButton(
            onPressed: () => client.auth.signOut(),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: client.from('sale_windows').select().order('mulai'),
        builder: (context, snap) {
          if (snap.hasError) {
            return Center(child: Text('Error: ${snap.error}'));
          }
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final rows = snap.data!;
          return ListView.builder(
            itemCount: rows.length,
            itemBuilder: (_, i) => ListTile(
              title: Text(rows[i]['label']),
              subtitle: Text(
                '${rows[i]['mulai']} · ${rows[i]['terisi']}/${rows[i]['kapasitas']}',
              ),
              trailing: TextButton(
                onPressed: () async {
                  final messenger = ScaffoldMessenger.of(context);
                  try {
                    await client.rpc('book_window',
                        params: {'p_window': rows[i]['id']});
                    messenger.showSnackBar(
                      const SnackBar(content: Text('Jadwal beli tersimpan')),
                    );
                  } on PostgrestException catch (e) {
                    messenger.showSnackBar(SnackBar(content: Text(e.message)));
                  }
                },
                child: const Text('Booking'),
              ),
            ),
          );
        },
      ),
    );
  }
}
