import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:blockpay/constants/colors.dart';
import 'package:blockpay/providers/wallet_provider.dart';
import 'package:blockpay/screens/splash_screen.dart';

void main() {
  runApp(const BlockPayApp());
}

class BlockPayApp extends StatelessWidget {
  const BlockPayApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => WalletProvider())],
      child: MaterialApp(
        title: 'BlockPay',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: AppColors.primary,
            surface: AppColors.background,
          ),
          useMaterial3: true,
          textTheme: GoogleFonts.outfitTextTheme(),
          appBarTheme: const AppBarTheme(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            elevation: 0,
          ),
        ),
        home: const SplashScreen(),
      ),
    );
  }
}
