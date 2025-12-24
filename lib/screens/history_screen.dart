import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:blockpay/constants/colors.dart';
import 'package:blockpay/constants/strings.dart';
import 'package:blockpay/providers/wallet_provider.dart';
import 'package:intl/intl.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final wallet = Provider.of<WalletProvider>(context);
    final allTransactions = wallet.transactions; // Live data

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Transaction History'), elevation: 0),
      body: allTransactions.isEmpty
          ? const Center(child: Text("No transactions yet."))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: allTransactions.length,
              itemBuilder: (context, index) {
                final txn = allTransactions[index];
                return Card(
                  elevation: 0,
                  color: AppColors.surface,
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: txn.isCredit
                          ? AppColors.success.withValues(alpha: 0.1)
                          : AppColors.error.withValues(alpha: 0.1),
                      child: Icon(
                        txn.isCredit
                            ? Icons.arrow_downward
                            : Icons.arrow_upward,
                        color: txn.isCredit
                            ? AppColors.success
                            : AppColors.error,
                      ),
                    ),
                    title: Text(
                      txn.title,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      DateFormat('MMM d, yyyy h:mm a').format(txn.date),
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                    trailing: Text(
                      '${txn.isCredit ? "+" : "-"} ${AppStrings.currencySymbol}${txn.amount.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: txn.isCredit
                            ? AppColors.success
                            : AppColors.error,
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
