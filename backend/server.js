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

// MongoDB Connection (Remote Atlas)
const MONGO_URI = 'mongodb+srv://vinnirnr66_db_user:Spoo123@vinayak.5nqks4k.mongodb.net/?retryWrites=true&w=majority&appName=Cluster0';

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

        await seedAdmin();
    })
    .catch(err => console.error('❌ MongoDB Connection Error:', err));

// Seed Admin Helper
const seedAdmin = async () => {
    try {
        const adminEmail = "admin@blockpay.com";
        const exists = await User.findOne({ email: adminEmail });
        if (!exists) {
            console.log("Creating Admin User...");
            const admin = new User({
                name: "BlockPay Admin",
                email: adminEmail,
                password: "admin123",
                walletAddress: adminEmail
            });
            await admin.save();
            // Mint Initial Supply
            const newTxn = new Transaction({
                sender: "System",
                receiver: adminEmail,
                amount: 1000000, // 1 Million Coin Reserve
                txnId: `GENESIS-${Date.now()}`,
                hash: "GENESIS_BLOCK"
            });
            await newTxn.save();
            console.log("✅ Admin Seeded: admin@blockpay.com / admin123");
        }
    } catch (e) {
        console.error("Seed Error:", e);
    }
};

// --- Helper Functions ---

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
        if (txn.receiver === address) {
            balance += txn.amount; // Credit
        }
        if (txn.sender === address) {
            balance -= txn.amount; // Debit
        }
    });

    console.log(`💰 Balance Check for [${address}]: Found ${txns.length} txns. Final Balance: ${balance}`);
    return balance;
};

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

        const walletAddress = email;

        const newUser = new User({
            name,
            email,
            password: password || "default123",
            walletAddress
        });

        await newUser.save();

        // Welcome Bonus (Persistent)
        try {
            const bonusTxn = new Transaction({
                sender: "system", // consistent lowercase system
                receiver: walletAddress,
                amount: 1000,
                txnId: `WELCOME-${Date.now()}-${Math.floor(Math.random() * 1000)}`,
                hash: crypto.createHash('sha256').update(`WELCOME-${Date.now()}`).digest('hex')
            });
            await bonusTxn.save();
            console.log(`✅ Welcome Bonus Minted for ${walletAddress}`);
        } catch (txnError) {
            console.error("❌ Failed to mint Welcome Bonus:", txnError);
        }

        res.json({ status: "SUCCESS", message: "User Registered", userId: newUser.email, name: newUser.name });
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

        if (!user) return res.status(400).json({ error: "User not found" });

        if (user.password !== password) {
            return res.status(400).json({ error: "Invalid Password" });
        }

        res.json({
            status: "SUCCESS",
            userId: user.email,
            name: user.name,
            walletAddress: user.walletAddress
        });
    } catch (e) {
        res.status(500).json({ error: "Login Failed", details: e.message });
    }
});

// 3. Get Balance (Persistent)
app.get('/api/wallet/:id/balance', async (req, res) => {
    try {
        const address = req.params.id.toLowerCase(); // Force Lowercase
        const balance = await calculateBalance(address);
        res.json({ address, balance });
    } catch (e) {
        res.status(500).json({ error: "Balance Check Failed" });
    }
});

// 4. Get History (Persistent)
app.get('/api/wallet/:id/history', async (req, res) => {
    try {
        const address = req.params.id.toLowerCase(); // Force Lowercase
        // Find transactions where user is sender OR receiver
        const history = await Transaction.find({
            $or: [{ sender: address }, { receiver: address }]
        }).sort({ timestamp: -1 }); // Newest first

        res.json({ address, history });
    } catch (e) {
        res.status(500).json({ error: "History Fetch Failed" });
    }
});

// 5. Send Transaction (Persistent & Safe)
app.post('/api/transaction/send', async (req, res) => {
    let { sender, receiver, amount } = req.body;

    if (!sender || !receiver || !amount) {
        return res.status(400).json({ error: "Missing details" });
    }

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

        // B. Check Balance
        const currentBalance = await calculateBalance(sender);
        const txnAmount = parseFloat(amount);

        // Exempt System from balance check
        if (sender !== "system" && sender !== "faucet" && txnAmount > currentBalance) {
            return res.status(400).json({
                error: "Insufficient Funds",
                currentBalance,
                attempted: txnAmount
            });
        }

        // C. Create & Save Transaction
        const txnId = `TXN-${Date.now()}-${Math.floor(Math.random() * 10000)}`;
        // Simulated Hash
        const hashPayload = `${sender}${receiver}${amount}${txnId}`;
        const hash = crypto.createHash('sha256').update(hashPayload).digest('hex');

        const newTxn = new Transaction({
            sender,
            receiver,
            amount: txnAmount,
            txnId,
            hash
        });

        await newTxn.save();
        console.log(`✅ Transaction Saved: ${sender} -> ${receiver} ($${amount})`);

        res.json({
            status: "SUCCESS",
            message: "Transaction Settled",
            data: {
                txnId,
                newBalance: sender === "system" ? 0 : currentBalance - txnAmount
            }
        });

    } catch (e) {
        console.error("Txn Error:", e);
        res.status(500).json({ error: "Transaction Failed", details: e.message });
    }
});

// 6. Chain (For Admin)
app.get('/api/chain', async (req, res) => {
    const chain = await Transaction.find().sort({ timestamp: -1 }).limit(50);
    res.json(chain);
});

app.listen(PORT, () => {
    console.log(`BlockPay Persistent Server running on port ${PORT}`);
});
