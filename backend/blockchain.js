const SHA256 = require("crypto-js/sha256");

class Block {
    constructor(index, timestamp, data, previousHash = '') {
        this.index = index;
        this.timestamp = timestamp;
        this.data = data;
        this.previousHash = previousHash;
        this.hash = this.calculateHash();
        this.nonce = 0;
    }

    calculateHash() {
        return SHA256(this.index + this.previousHash + this.timestamp + JSON.stringify(this.data) + this.nonce).toString();
    }

    mineBlock(difficulty) {
        while (this.hash.substring(0, difficulty) !== Array(difficulty + 1).join("0")) {
            this.nonce++;
            this.hash = this.calculateHash();
        }
    }
}

class Blockchain {
    constructor() {
        this.chain = [this.createGenesisBlock()];
        this.difficulty = 2; // Low difficulty for real-time demo speed
    }

    createGenesisBlock() {
        return new Block(0, Date.now(), { sender: "SYSTEM", receiver: "Genesis", amount: 0 }, "0");
    }

    getLatestBlock() {
        return this.chain[this.chain.length - 1];
    }

    addTransaction(transaction) {
        // In a real crypto, this would go to a pending pool. 
        // For our T+0 Simulator, we mine immediately.

        const newBlock = new Block(
            this.chain.length,
            Date.now(),
            transaction,
            this.getLatestBlock().hash
        );

        // Simulate "Mining" (Proof of Work)
        console.log("Mining block...");
        newBlock.mineBlock(this.difficulty);
        console.log("Block mined: " + newBlock.hash);

        this.chain.push(newBlock);
        return newBlock;
    }

    isChainValid() {
        for (let i = 1; i < this.chain.length; i++) {
            const currentBlock = this.chain[i];
            const previousBlock = this.chain[i - 1];

            if (currentBlock.hash !== currentBlock.calculateHash()) return false;
            if (currentBlock.previousHash !== previousBlock.hash) return false;
        }
        return true;
    }

    getBalanceOfAddress(address) {
        let balance = 0;

        // Initial "Faucet" for Demo Users
        const initialBalances = {
            "user@test.com": 7500, // Changed to prove it's live
            "Dad": 10000,
            "Mom": 8000
        };
        if (initialBalances[address]) balance = initialBalances[address];

        for (const block of this.chain) {
            const trans = block.data;
            if (trans.sender === address) {
                balance -= parseFloat(trans.amount);
            }
            if (trans.receiver === address) {
                balance += parseFloat(trans.amount);
            }
        }
        return balance;
    }

    getHistory(address) {
        const history = [];
        for (const block of this.chain) {
            if (block.index === 0) continue; // Skip genesis
            const t = block.data;
            if (t.sender === address || t.receiver === address) {
                history.push({
                    ...t,
                    timestamp: block.timestamp,
                    hash: block.hash,
                    isCredit: t.receiver === address
                });
            }
        }
        return history.reverse();
    }
}

module.exports = { Blockchain, Block };
