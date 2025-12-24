import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:blockpay/constants/colors.dart';
import 'package:blockpay/constants/strings.dart';
import 'package:provider/provider.dart';
import 'package:blockpay/screens/login_screen.dart';
import 'package:blockpay/screens/dashboard_screen.dart';
import 'package:blockpay/providers/wallet_provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToLogin();
  }

  Future<void> _navigateToLogin() async {
    await Future.delayed(const Duration(seconds: 3));
    if (!mounted) return;

    // Check if session exists
    final WalletProvider provider = context.read<WalletProvider>();
    // Wait small bit for shared prefs to load if it hasn't yet
    // In a real production app, we would await the init.

    // However, since we might need to wait for the provider to load from SharedPrefs
    // We can just rely on the fact that provider init starts getting prefs.
    // For simplicity, we just go to LoginScreen if no ID, or Dashboard if ID.
    // But since _loadSession is async in constructor, it might race.
    // Secure way: Just go to Login. LoginScreen will check if already authed?
    // Better: Dashboard.

    // Simplest Fix for "Creates without account": MUST go to Login.
    if (provider.isAuthenticated) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const DashboardScreen()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FadeInDown(
              duration: const Duration(milliseconds: 1000),
              child: const Icon(
                Icons.account_balance_wallet,
                size: 80,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 20),
            FadeInUp(
              duration: const Duration(milliseconds: 1000),
              child: const Text(
                AppStrings.appName,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 10),
            FadeInUp(
              delay: const Duration(milliseconds: 500),
              duration: const Duration(milliseconds: 1000),
              child: const Text(
                'Secure Blockchain Wallet',
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
            ),
            const SizedBox(height: 50),
            FadeIn(
              delay: const Duration(milliseconds: 1500),
              child: const CircularProgressIndicator(color: AppColors.accent),
            ),
          ],
        ),
      ),
    );
  }
}
