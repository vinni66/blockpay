import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:blockpay/constants/colors.dart';
import 'package:blockpay/constants/strings.dart';
import 'package:blockpay/screens/dashboard_screen.dart';

class TransactionSuccessScreen extends StatelessWidget {
  final String amount;
  final String receiver;
  final String txnId;

  const TransactionSuccessScreen({
    super.key,
    required this.amount,
    required this.receiver,
    required this.txnId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FadeInDown(
                child: const CircleAvatar(
                  radius: 50,
                  backgroundColor: AppColors.success,
                  child: Icon(Icons.check, size: 60, color: Colors.white),
                ),
              ),
              const SizedBox(height: 24),
              FadeInUp(
                child: const Text(
                  'Payment Successful!',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              FadeInUp(
                delay: const Duration(milliseconds: 200),
                child: Text(
                  'Sent ${AppStrings.currencySymbol}$amount to $receiver',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Receipt Card
              FadeInUp(
                delay: const Duration(milliseconds: 400),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Transaction ID:',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                      Text(
                        txnId,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 48),

              FadeInUp(
                delay: const Duration(milliseconds: 600),
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const DashboardScreen(),
                        ),
                        (route) => false,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Back to Home'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
