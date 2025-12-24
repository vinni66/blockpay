import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:blockpay/constants/colors.dart';
import 'package:blockpay/screens/transaction_success_screen.dart';
import 'package:provider/provider.dart';
import 'package:blockpay/providers/wallet_provider.dart';

class TransactionProcessingScreen extends StatefulWidget {
  final String receiver;
  final double amount;

  const TransactionProcessingScreen({
    super.key,
    required this.receiver,
    required this.amount,
  });

  @override
  State<TransactionProcessingScreen> createState() =>
      _TransactionProcessingScreenState();
}

class _TransactionProcessingScreenState
    extends State<TransactionProcessingScreen> {
  int _currentStep = 0;
  final List<String> _steps = [
    "Establishing Secure Connection...",
    "Signing Transaction with Private Key...",
    "Broadcasting to Polygon Network...",
    "Waiting for Block Confirmation...",
    "Updating Immutable Ledger...",
  ];

  @override
  void initState() {
    super.initState();
    _processTransaction();
  }

  void _processTransaction() async {
    for (int i = 0; i < _steps.length; i++) {
      await Future.delayed(
        const Duration(milliseconds: 1500),
      ); // Simulate network delay
      if (!mounted) return;
      setState(() {
        _currentStep = i;
      });
    }

    if (!mounted) return;

    // Actual Logic Execution
    try {
      await Provider.of<WalletProvider>(
        context,
        listen: false,
      ).sendMoney(widget.receiver, widget.amount);

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => TransactionSuccessScreen(
            amount: widget.amount.toStringAsFixed(2),
            receiver: widget.receiver,
            txnId: "TXN-${DateTime.now().millisecondsSinceEpoch}",
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Failed: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Rotating Blockchain Icon
              SpinPerfect(
                infinite: true,
                duration: const Duration(seconds: 4),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: const Icon(Icons.hub, size: 60, color: Colors.white),
                ),
              ),
              const SizedBox(height: 48),

              // Dynamic Step Text
              SizedBox(
                height: 60,
                child: FadeInUp(
                  key: ValueKey(_currentStep), // Animate when step changes
                  child: Text(
                    _steps[_currentStep],
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),
              LinearProgressIndicator(
                value: (_currentStep + 1) / _steps.length,
                backgroundColor: Colors.white24,
                color: AppColors.accent,
              ),
              const SizedBox(height: 8),
              Text(
                "${((_currentStep + 1) / _steps.length * 100).toInt()}%",
                style: const TextStyle(color: Colors.white70),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
