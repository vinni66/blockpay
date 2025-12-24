import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:blockpay/models/transaction.dart';

class Block {
  final int index;
  final int timestamp;
  final Transaction data;
  final String previousHash;
  late String hash;

  Block({
    required this.index,
    required this.timestamp,
    required this.data,
    required this.previousHash,
  }) {
    hash = calculateHash();
  }

  String calculateHash() {
    final payload = '$index$timestamp$previousHash${data.id}${data.amount}';
    final bytes = utf8.encode(payload);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
}

class BlockchainService {
  List<Block> chain = [];

  BlockchainService() {
    _createGenesisBlock();
  }

  void _createGenesisBlock() {
    // Genesis Transaction
    final genesisTxn = Transaction(
      id: "GENESIS",
      title: "Genesis Block",
      amount: 0,
      date: DateTime.now(),
      isCredit: true,
    );

    chain.add(
      Block(
        index: 0,
        timestamp: DateTime.now().millisecondsSinceEpoch,
        data: genesisTxn,
        previousHash: "0",
      ),
    );
  }

  Block get latestBlock => chain.last;

  void addBlock(Transaction transaction) {
    final newBlock = Block(
      index: chain.length,
      timestamp: DateTime.now().millisecondsSinceEpoch,
      data: transaction,
      previousHash: latestBlock.hash,
    );
    chain.add(newBlock);
    // In a real blockchain, we would broadcast this.
    // For local simulation, it's just added to the memory list.
  }

  bool isChainValid() {
    for (int i = 1; i < chain.length; i++) {
      final currentBlock = chain[i];
      final previousBlock = chain[i - 1];

      if (currentBlock.hash != currentBlock.calculateHash()) {
        return false;
      }

      if (currentBlock.previousHash != previousBlock.hash) {
        return false;
      }
    }
    return true;
  }
}
