import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:blockpay/constants/colors.dart';
import 'package:blockpay/constants/strings.dart';
import 'package:blockpay/providers/wallet_provider.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  final _amountController = TextEditingController();
  late TextEditingController _receiverController; // Initialize in initState
  bool _isLoading = false;
  List<dynamic> _fullChain = [];

  @override
  void initState() {
    super.initState();
    final userId = Provider.of<WalletProvider>(context, listen: false).userId;
    _receiverController = TextEditingController(text: userId);
    _fetchChain();
  }

  Future<void> _fetchChain() async {
    // Fetch full blockchain for transparency
    try {
      final res = await http.get(Uri.parse('${WalletProvider.baseUrl}/chain'));
      if (res.statusCode == 200) {
        setState(() {
          _fullChain = json.decode(res.body);
        });
      }
    } catch (e) {
      debugPrint("Admin Error: $e");
    }
  }

  Future<void> _mintTokens() async {
    setState(() => _isLoading = true);
    final amount = double.tryParse(_amountController.text) ?? 0.0;
    try {
      await Provider.of<WalletProvider>(context, listen: false).mintCurrency(
        _receiverController.text.trim(), // Actual Target
        amount,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("✅ Minting Successful")));

      _fetchChain(); // Refresh list
      _amountController.clear();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Failed: $e")));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("Central Bank Admin"),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _fetchChain();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Refreshing Ledger...")),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Minting Section
            const Text(
              "Mint Virtual Currency",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    TextField(
                      controller: _receiverController,
                      decoration: const InputDecoration(
                        labelText: "Target Email Address", // Clarified Hint
                        hintText: "e.g. user@test.com",
                      ),
                    ),
                    TextField(
                      controller: _amountController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: "Amount to Mint",
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isLoading ? null : _mintTokens,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          foregroundColor: Colors.white,
                        ),
                        icon: const Icon(Icons.print),
                        label: _isLoading
                            ? const CircularProgressIndicator()
                            : const Text("INITIATE MINTING"),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),
            const Text(
              "Global Ledger Monitor",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            // Ledger List
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _fullChain.length,
              itemBuilder: (context, index) {
                final txn =
                    _fullChain[index]; // Use parsed list directly (Newest First)

                // MongoDB keys: sender, receiver, amount, hash, txnId
                String sender = txn['sender'] ?? "Unknown";
                String receiver = txn['receiver'] ?? "Unknown";
                double amount =
                    double.tryParse(txn['amount'].toString()) ?? 0.0;
                String hash = txn['hash'] ?? "";
                String txnId = txn['txnId'] ?? "???";

                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  color: Colors.grey[100],
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.black12,
                      child: Icon(Icons.receipt_long, color: Colors.black),
                    ),
                    title: Text(
                      txnId,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Hash: ${hash.length > 15 ? hash.substring(0, 15) + '...' : hash}",
                          style: TextStyle(fontSize: 10),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              sender,
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 4),
                              child: Icon(Icons.arrow_right_alt, size: 16),
                            ),
                            Text(
                              receiver,
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ],
                    ),
                    trailing: Text(
                      "${AppStrings.currencySymbol}$amount",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
