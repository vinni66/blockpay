import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:blockpay/models/transaction.dart';
import 'dart:io';

class WalletProvider extends ChangeNotifier {
  // Dynamic Host for Android vs Windows/Web
  static String get baseUrl {
    if (kIsWeb) return 'http://127.0.0.1:3000/api';
    if (Platform.isAndroid) return 'http://10.0.2.2:3000/api';
    return 'http://127.0.0.1:3000/api'; // Windows/iOS/Linux
  }

  String? _userId; // Dynamic User ID (Email)
  String? _userName;

  double _balance = 0.0;
  List<Transaction> _transactions = [];
  bool _isLoading = false;

  String get userId => _userId ?? "";
  String get userName => _userName ?? "User";
  double get balance => _balance;
  List<Transaction> get transactions => _transactions;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _userId != null;

  // --- Auth Methods ---

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/login'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode({
              'email': email.toLowerCase(),
              'password': password,
            }),
          )
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _userId = data['userId'];
        _userName = data['name'];
        await fetchWalletData(); // Load data after login
        return true;
      } else {
        throw Exception(json.decode(response.body)['error']);
      }
    } catch (e) {
      debugPrint("Login Error: $e");
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> register(String name, String email, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/register'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode({
              'name': name,
              'email': email.toLowerCase(),
              'password': password,
            }),
          )
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _userId = data['userId'];
        _userName = data['name'];
        await fetchWalletData();
        return true;
      } else {
        final errorJson = json.decode(response.body);
        throw Exception("${errorJson['error']}: ${errorJson['details'] ?? ''}");
      }
    } catch (e) {
      debugPrint("Register Error: $e");
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void logout() {
    _userId = null;
    _userName = null;
    _balance = 0.0;
    _transactions = [];
    notifyListeners();
  }

  // --- Wallet Data ---

  Future<void> fetchWalletData() async {
    if (_userId == null) return;

    _isLoading = true;
    notifyListeners();

    // 1. Fetch Balance (Independent Try-Catch)
    try {
      final balanceRes = await http
          .get(Uri.parse('$baseUrl/wallet/$_userId/balance'))
          .timeout(const Duration(seconds: 5));

      if (balanceRes.statusCode == 200) {
        final data = json.decode(balanceRes.body);
        _balance = (data['balance'] as num).toDouble();
      }
    } catch (e) {
      debugPrint("Error fetching balance: $e");
      // Do NOT reset balance to 0 on failure if we want to show stale data,
      // but for now, we leave it as is or reset if critical.
      // _balance = 0.0; // decision: keep last known good or 0?
      // Safe to keep old balance or 0 if it failed.
    }

    // 2. Fetch History (Independent Try-Catch)
    try {
      final historyRes = await http
          .get(Uri.parse('$baseUrl/wallet/$_userId/history'))
          .timeout(const Duration(seconds: 5));

      if (historyRes.statusCode == 200) {
        final data = json.decode(historyRes.body);
        final List<dynamic> history = data['history'];

        _transactions = history.map((json) {
          // Manual isCredit logic because backend JSON doesn't have it
          final bool isCredit =
              (json['receiver'] as String).toLowerCase() ==
              _userId!.toLowerCase();

          return Transaction(
            id: json['hash'] != null
                ? json['hash'].substring(0, 10)
                : (json['txnId'] ?? "ID"),
            title: isCredit
                ? "Received from ${json['sender']}"
                : "Paid to ${json['receiver']}",
            amount: (json['amount'] as num).toDouble(),
            date: DateTime.parse(json['timestamp']),
            isCredit: isCredit,
          );
        }).toList();
      }
    } catch (e) {
      debugPrint("Error fetching history: $e");
      // Failed history shouldn't wipe balance
      _transactions = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> sendMoney(String receiver, double amount) async {
    if (_userId == null) return;

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/transaction/send'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'sender': _userId,
          'receiver': receiver.toLowerCase(),
          'amount': amount,
        }),
      );

      if (response.statusCode == 200) {
        await fetchWalletData();
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['error'] ?? "Transaction Failed");
      }
    } catch (e) {
      throw Exception("Network Error: $e");
    }
  }

  Future<void> mintCurrency(String target, double amount) async {
    // Admin/System Minting
    final response = await http.post(
      Uri.parse('$baseUrl/transaction/send'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'sender': "System",
        'receiver': target.toLowerCase(),
        'amount': amount,
      }),
    );

    if (response.statusCode == 200) {
      // If minting to self (Admin), refresh data.
      if (target == _userId) {
        await fetchWalletData();
      }
    } else {
      final errorData = json.decode(response.body);
      throw Exception(errorData['error'] ?? "Minting Failed");
    }
  }
}
