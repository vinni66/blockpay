require('dotenv').config();
const express = require('express');
const cors = require('cors');
const bodyParser = require('body-parser');
const mongoose = require('mongoose');
const { Blockchain } = require('./blockchain'); // Keep for hash logic if needed, or remove
const User = require('./models/User');
const Transaction = require('./models/Transaction');
const crypto = require('crypto'); // For generating hashes

const app = express();
const PORT = 3000;

// Middleware
app.use(cors());
app.use(bodyParser.json());

// Root Route for Vercel Health Check
app.get('/', (req, res) => {
    res.send('BlockPay Server is Running 🚀');
});

// MongoDB Connection (Remote Atlas)
const MONGO_URI = process.env.MONGO_URI;

if (!MONGO_URI) {
    console.error("❌ Fatal Error: MONGO_URI is not defined in environment variables.");
    process.exit(1);
}

mongoose.connect(MONGO_URI)
    .then(async () => {
        console.log('✅ Connected to MongoDB Atlas');

        // Fix: Drop stale 'username' index if it exists (causes E11000 on nulls)
        try {
            await User.collection.dropIndex('username_1');
            console.log('⚠️  Dropped stale index: username_1');
        } catch (e) {
            // Index likely doesn't exist, which is fine.
        }
    })
    .catch(err => console.error('❌ MongoDB Connection Error:', err));

// --- Routes ---

// 1. Register User
app.post('/api/register', async (req, res) => {
    try {
        const { name, password } = req.body;
        const email = req.body.email.toLowerCase(); // Force Lowercase

        const existingUser = await User.findOne({ email });
        if (existingUser) {
            return res.status(400).json({ error: "User already exists" });
        }

        // Give Welcome Bonus
        const newUser = new User({ name, email, password });
        await newUser.save();

        // Bonus Transaction (100 VC)
        try {
            const bonusTxn = new Transaction({
                sender: "System",
                receiver: email,
                amount: 100.00,
                txnId: `BONUS-${Date.now()}`,
                hash: crypto.createHash('sha256').update(`BONUS-${Date.now()}`).digest('hex'),
                isCredit: true
            });
            await bonusTxn.save();
            console.log(`🎁 Welcome Bonus sent to ${email}`);
        } catch (txnError) {
            console.error("⚠️ Failed to send Welcome Bonus:", txnError);
        }

        res.json({ message: "User registered successfully", userId: email, name: name });
    } catch (e) {
        console.error("Register Error:", e);
        res.status(500).json({ error: "Registration Failed", details: e.message });
    }
});

// 2. Login User
app.post('/api/login', async (req, res) => {
    try {
        const { password } = req.body;
        const email = req.body.email.toLowerCase(); // Force Lowercase

        const user = await User.findOne({ email });
        if (!user || user.password !== password) {
            return res.status(400).json({ error: "Invalid credentials" });
        }
        res.json({ message: "Login successful", userId: user.email, name: user.name });
    } catch (e) {
        res.status(500).json({ error: "Login Error" });
    }
});

// 3. Helper: Calculate Balance using JS Loop (Robust)
const calculateBalance = async (rawAddress) => {
    // 0. Sanitize
    const address = rawAddress.toLowerCase();

    // 1. Fetch ALL transactions involving this user
    const txns = await Transaction.find({
        $or: [{ sender: address }, { receiver: address }]
    });

    // 2. Calculate in JS (Robust & Loggable)
    let balance = 0.0;

    txns.forEach(txn => {
        // Standardize comparison just in case
        const sender = txn.sender.toLowerCase();
        const receiver = txn.receiver.toLowerCase();

        if (receiver === address) {
            balance += txn.amount; // Credit
        }
        if (sender === address) {
            balance -= txn.amount; // Debit
        }
    });

    console.log(`💰 Balance Check for [${address}]: Found ${txns.length} txns. Final Balance: ${balance}`);
    return balance;
};


// 4. API: Get Balance
app.get('/api/wallet/:id/balance', async (req, res) => {
    try {
        const address = req.params.id.toLowerCase(); // Force Lowercase
        const balance = await calculateBalance(address);
        res.json({ address, balance });
    } catch (e) {
        console.error("Balance Error:", e);
        res.status(500).json({ error: "Failed to fetch balance" });
    }
});

// 5. API: Get History
app.get('/api/wallet/:id/history', async (req, res) => {
    try {
        const address = req.params.id.toLowerCase(); // Force Lowercase
        // Find transactions where user is sender OR receiver
        const history = await Transaction.find({
            $or: [{ sender: address }, { receiver: address }]
        }).sort({ timestamp: -1 }); // Newest first

        res.json({ address, history });
    } catch (e) {
        res.status(500).json({ error: "Failed to fetch history" });
    }
});

// 6. Send Transaction
app.post('/api/transaction/send', async (req, res) => {
    let { sender, receiver, amount } = req.body;

    // Force Lowercase
    sender = sender.toLowerCase();
    receiver = receiver.toLowerCase();

    try {
        // A. Validate Receiver Exists (The "Real Account" Check)
        // Check for 'system' case-insensitive
        if (receiver !== "system") {
            const receiverUser = await User.findOne({ email: receiver });
            if (!receiverUser) {
                return res.status(404).json({ error: "Receiver Account Not Found" });
            }
        }

        // B. Check Balance (unless sender is System)
        if (sender !== "system") {
            const currentBalance = await calculateBalance(sender);
            if (currentBalance < amount) {
                return res.status(400).json({ error: "Insufficient Funds" });
            }
        }

        // C. Create Transaction
        const newTxn = new Transaction({
            sender,
            receiver,
            amount: parseFloat(amount),
            txnId: `TXN-${Date.now()}`,
            hash: crypto.createHash('sha256').update(`TXN-${Date.now()}`).digest('hex')
        });

        await newTxn.save();
        res.json({ message: "Transaction Settled", data: newTxn });

    } catch (e) {
        console.error("Txn Error:", e);
        res.status(500).json({ error: "Transaction Failed", details: e.message });
    }
});

// 7. Get Chain (Debug)
app.get('/api/chain', async (req, res) => {
    const txns = await Transaction.find().sort({ timestamp: -1 });
    res.json(txns);
});

// Admin Seeder (Optional)
const seedAdmin = async () => {
    const adminEmail = "bharath@gmail.com";
    const exists = await User.findOne({ email: adminEmail });
    if (!exists) {
        await new User({ name: "Bharath Admin", email: adminEmail, password: "admin" }).save();
        console.log("👑 Admin Seeded");

        // Genesis Mint
        const newTxn = new Transaction({
            sender: "system", // consistent lowercase system
            receiver: adminEmail,
            amount: 1000000, // 1 Million Coin Reserve
            txnId: `GENESIS-${Date.now()}`,
            hash: "GENESIS_BLOCK"
        });
        await newTxn.save();
        console.log("💰 Genesis Minted");
    }
};
seedAdmin();

// Start Server - Export for Vercel
app.listen(PORT, () => {
    console.log(`BlockPay Persistent Server running on port ${PORT}`);
});

module.exports = app;
