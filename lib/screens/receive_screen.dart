import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:blockpay/constants/colors.dart';
import 'package:provider/provider.dart';
import 'package:blockpay/providers/wallet_provider.dart';
import 'package:share_plus/share_plus.dart';

class ReceiveScreen extends StatelessWidget {
  const ReceiveScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // In a real app, this would be the actual public key from the wallet
    // Consume Provider to get dynamic User ID
    final wallet = Provider.of<WalletProvider>(context);
    final userId = wallet.userId;

    // QR ID
    final qrData = "blockpay:$userId";

    return Scaffold(
      backgroundColor: AppColors.primary,
      appBar: AppBar(
        title: const Text('Receive Money'),
        backgroundColor: AppColors.primary, // Seamless look
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // QR Code (Centerpiece)
              Center(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: QrImageView(
                    data: qrData, // Use the correct qrData variable
                    version: QrVersions.auto,
                    size: 200.0,
                    backgroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Address Display
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white30),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      userId, // Use correct userId variable
                      style: const TextStyle(
                        fontFamily: 'Courier',
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: () {
                        Clipboard.setData(
                          ClipboardData(text: userId),
                        ); // Use userId
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("ID Copied!")),
                        );
                      },
                      icon: const Icon(Icons.copy, color: Colors.white),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 48),

              // Request Button (Share)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Share.share(
                      "Pay me on BlockPay! My ID is: $userId",
                    ); // Use userId
                  },
                  icon: const Icon(Icons.share),
                  label: const Text("Share My Payment ID"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),

              // Dev Tool: Faucet Button (Hidden/Optional)
              const Spacer(),
              TextButton(
                onPressed: () {
                  Provider.of<WalletProvider>(
                    context,
                    listen: false,
                  ).mintCurrency(wallet.userId, 1000.0);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Dev Tool: Added 1000 VC')),
                  );
                },
                child: const Text(
                  "Dev Faucet (Add Funds)",
                  style: TextStyle(color: Colors.white54),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
