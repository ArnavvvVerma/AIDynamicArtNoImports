# 🧠 AI Dynamic Art NFT (Flow Blockchain)

This project contains a **fully on-chain NFT smart contract** written in **pure Solidity-style syntax (conceptual reference)** — designed for **AI-generated art with dynamic metadata**, adapted for deployment on the **Flow blockchain**.

The NFTs represent **AI-created generative art**, evolving in real time based on blockchain data.  
Every token renders its own metadata and SVG image on-chain, emphasizing **decentralization and permanence**.

---

## 📜 Smart Contract Details

- **Blockchain:** Flow  
- **Deployed Address:** `0x0fFE1F20a335944f7934aA53D2629bBfC9d94E4e`  
- **Contract Name:** AI Dynamic Art  
- **Symbol:** AIDA  
- **Standard:** NFT (Flow-compatible conceptual model)  
- **Dependencies:** None (no imports)  
- **Constructor:** None  
- **Input Fields:** None (fully autonomous minting)

---

## 🎨 Features

✅ **Pure On-Chain Metadata**  
Each NFT stores metadata and images on-chain, using encoded Base64 JSON + SVG.  
No IPFS or centralized storage required.

✅ **Dynamic Artwork**  
Each artwork evolves based on live blockchain data — timestamp, block hash, or random seed — creating unique traits and styles per mint.

✅ **No External Dependencies**  
All logic lives inside the smart contract. No constructor, no imports, no parameters.

✅ **Simple Minting**  
Mint with a single call:
```solidity
mint()
