const mongoose = require('mongoose');

const TransactionSchema = new mongoose.Schema({
    sender: { type: String, required: true },   // Wallet Address / Email
    receiver: { type: String, required: true }, // Wallet Address / Email
    amount: { type: Number, required: true },
    timestamp: { type: Date, default: Date.now },
    status: { type: String, default: 'SUCCESS' },
    hash: { type: String, required: false }, // Simulated Block Hash
    txnId: { type: String, required: true, unique: true } // Unique Transaction ID
});

module.exports = mongoose.model('Transaction', TransactionSchema);
