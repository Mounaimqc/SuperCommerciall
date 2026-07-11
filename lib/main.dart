import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/barcode_provider.dart';
import 'providers/clients_provider.dart';
import 'providers/product_provider.dart';
import 'providers/sales_provider.dart';
import 'providers/purchases_provider.dart';
import 'providers/charge_provider.dart';
import 'providers/statistics_provider.dart';
import 'providers/settings_provider.dart';
import 'providers/fournisseur_provider.dart';
import 'providers/document_provider.dart';
import 'providers/purchase_provider.dart';
import 'providers/sale_provider.dart';
import 'screens/splash_screen.dart';
import 'utils/document_id_mapper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DocumentIdMapper.initialize();
  runApp(const SuperCommercialApp());
}

/// Main Application Entry Point with MultiProvider and Material 3 Styling
class SuperCommercialApp extends StatelessWidget {
  const SuperCommercialApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ClientsProvider()),
        ChangeNotifierProvider(create: (_) => ProductProvider()),
        ChangeNotifierProvider(create: (_) => BarcodeProvider()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProvider(create: (_) => SalesProvider()),
        ChangeNotifierProvider(create: (_) => PurchasesProvider()),
        ChangeNotifierProvider(create: (_) => ChargeProvider()),
        ChangeNotifierProvider(create: (_) => StatisticsProvider()),
        ChangeNotifierProvider(create: (_) => FournisseurProvider()),
        ChangeNotifierProvider(create: (_) => DocumentProvider()),
        ChangeNotifierProvider(create: (_) => PurchaseProvider()),
        ChangeNotifierProvider(create: (_) => SaleProvider()),
      ],
      child: Consumer<SettingsProvider>(
        builder: (context, settings, _) {
          return MaterialApp(
            title: 'Super Commercial',
            debugShowCheckedModeBanner: false,
            themeMode: settings.themeMode,
            theme: ThemeData(
              useMaterial3: true,
              brightness: Brightness.light,
              colorScheme: ColorScheme.fromSeed(
                seedColor: const Color(0xFF48C78E), // Green Seed
                brightness: Brightness.light,
              ),
              fontFamily: 'Inter',
            ),
            darkTheme: ThemeData(
              useMaterial3: true,
              brightness: Brightness.dark,
              colorScheme: ColorScheme.fromSeed(
                seedColor: const Color(0xFF48C78E),
                brightness: Brightness.dark,
              ),
              fontFamily: 'Inter',
            ),
            home: const SplashScreen(),
          );
        },
      ),
    );
  }
}
