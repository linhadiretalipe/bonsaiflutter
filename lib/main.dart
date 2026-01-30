import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'core/theme/app_theme.dart';
import 'presentation/screens/main_screen.dart';
import 'presentation/screens/wallet_setup_screen.dart';
import 'src/rust/api.dart';
import 'src/rust/frb_generated.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await RustLib.init();
  runApp(const ProviderScope(child: BonsaiApp()));
}

class BonsaiApp extends StatelessWidget {
  const BonsaiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bonsai Mobile',
      theme: AppTheme.darkTheme,
      home: const WalletCheckScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

/// Screen that checks if wallet exists and routes accordingly
class WalletCheckScreen extends StatefulWidget {
  const WalletCheckScreen({super.key});

  @override
  State<WalletCheckScreen> createState() => _WalletCheckScreenState();
}

class _WalletCheckScreenState extends State<WalletCheckScreen> {
  @override
  void initState() {
    super.initState();
    _checkWallet();
  }

  Future<void> _checkWallet() async {
    final dir = await getApplicationDocumentsDirectory();
    final dataDir = '${dir.path}/bonsai';
    final walletExists = await checkWalletExists(dataDir: dataDir);

    if (!mounted) return;

    if (walletExists) {
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => const MainScreen()));
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const WalletSetupScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppTheme.darkBackground,
      body: Center(
        child: CircularProgressIndicator(color: AppTheme.primaryGreen),
      ),
    );
  }
}
