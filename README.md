# 🧠 AI Dynamic Art NFT (On-Chain, No Imports / No Constructor)

This project contains a **fully on-chain NFT smart contract** written in **pure Solidity**, designed for **AI-generated art with dynamic metadata**.

The NFTs are created and rendered directly from the blockchain — no off-chain storage or dependencies.  
Every token produces its own evolving SVG artwork, which changes subtly based on block data such as timestamps and hashes.

---

## 📜 Smart Contract Details

- **Network:** Ethereum-compatible  
- **Deployed Address:** [`0x0fFE1F20a335944f7934aA53D2629bBfC9d94E4e`](https://etherscan.io/address/0x0fFE1F20a335944f7934aA53D2629bBfC9d94E4e)  
- **Name:** AI Dynamic Art  
- **Symbol:** AIDA  
- **Standard:** ERC-721 (minimal, fully self-contained)  
- **Dependencies:** None (no imports)  
- **Constructor:** None  
- **Mint Function:** No input fields (`mint()` auto-mints to `msg.sender`)

---

## 🎨 Features

✅ **Pure On-Chain Metadata**  
Each token’s metadata and image are generated entirely within the smart contract — stored as Base64 JSON + SVG.

✅ **Dynamic Artwork**  
Art dynamically evolves using blockchain data:
- `block.timestamp`
- `blockhash`
- `block.coinbase`

✅ **No External Calls / No Storage Reads for Metadata**  
All art data is computed in real-time, ensuring maximum transparency and verifiability.

✅ **Simple Minting**  
Anyone can mint by calling:
```solidity
mint()
