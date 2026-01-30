use std::path::Path;
use std::sync::Arc;
use std::collections::HashMap;
use tokio::sync::RwLock;
use once_cell::sync::Lazy;
use bitcoin::{Network, Block, OutPoint};
use bitcoin::bip32::{Xpriv, DerivationPath};
use bitcoin::secp256k1::Secp256k1;
use bdk_wallet::{Wallet, KeychainKind};
use bdk_floresta::{BlockConsumer, UtxoData};
use bip39::Mnemonic;
use std::fs;
use std::str::FromStr;
use rand::RngCore;

pub static WALLET_MANAGER: Lazy<Arc<RwLock<Option<WalletManager>>>> = 
    Lazy::new(|| Arc::new(RwLock::new(None)));

/// Transaction info exposed to Flutter
#[derive(Debug, Clone)]
pub struct WalletTransaction {
    pub txid: String,
    pub sent: u64,
    pub received: u64,
    pub fee: Option<u64>,
    pub is_confirmed: bool,
    pub confirmation_height: Option<u32>,
    pub timestamp: Option<u64>,
}

pub struct WalletManager {
    pub wallet: Wallet,
    pub network: Network,
    pending_blocks: Vec<(Block, u32)>, // blocks to process
}

impl WalletManager {
    pub fn init(data_dir: &str, network: Network) -> Result<Self, String> {
        let mnemonic_path = Path::new(data_dir).join("mnemonic.txt");

        let mnemonic = if mnemonic_path.exists() {
            let m_str = fs::read_to_string(&mnemonic_path)
                .map_err(|e| format!("Failed to read mnemonic: {}", e))?;
            Mnemonic::parse(m_str.trim())
                .map_err(|e| format!("Failed to parse mnemonic: {}", e))?
        } else {
            // Generate 16 bytes of entropy for 12-word mnemonic
            let mut entropy = [0u8; 16];
            rand::rng().fill_bytes(&mut entropy);
            let m = Mnemonic::from_entropy(&entropy)
                .map_err(|e| format!("Failed to create mnemonic: {}", e))?;
            fs::write(&mnemonic_path, m.to_string())
                .map_err(|e| format!("Failed to save mnemonic: {}", e))?;
            m
        };

        // Derive master key from mnemonic
        let seed = mnemonic.to_seed("");
        let secp = Secp256k1::new();
        let master_xpriv = Xpriv::new_master(network, &seed)
            .map_err(|e| format!("Failed to derive master key: {}", e))?;

        // Create BIP84 derivation paths
        // m/84'/coin'/0'/0 for external, m/84'/coin'/0'/1 for internal
        let coin_type = match network {
            Network::Bitcoin => 0,
            _ => 1, // testnet/signet/regtest
        };

        let external_path = DerivationPath::from_str(&format!("m/84'/{}'/0'/0", coin_type))
            .map_err(|e| format!("Invalid external path: {}", e))?;
        let internal_path = DerivationPath::from_str(&format!("m/84'/{}'/0'/1", coin_type))
            .map_err(|e| format!("Invalid internal path: {}", e))?;

        let external_xpriv = master_xpriv.derive_priv(&secp, &external_path)
            .map_err(|e| format!("Failed to derive external key: {}", e))?;
        let internal_xpriv = master_xpriv.derive_priv(&secp, &internal_path)
            .map_err(|e| format!("Failed to derive internal key: {}", e))?;

        // Create descriptors with the derived keys
        let external_descriptor: &'static str = Box::leak(
            format!("wpkh({}/*)", external_xpriv).into_boxed_str()
        );
        let internal_descriptor: &'static str = Box::leak(
            format!("wpkh({}/*)", internal_xpriv).into_boxed_str()
        );

        // Create in-memory wallet
        let wallet = Wallet::create(external_descriptor, internal_descriptor)
            .network(network)
            .create_wallet_no_persist()
            .map_err(|e| format!("Failed to create wallet: {}", e))?;

        Ok(Self {
            wallet,
            network,
            pending_blocks: Vec::new(),
        })
    }

    pub fn get_balance(&self) -> u64 {
        self.wallet.balance().total().to_sat()
    }

    pub fn get_address(&mut self) -> String {
        self.wallet.reveal_next_address(KeychainKind::External).address.to_string()
    }

    /// Add a block to be processed by the wallet
    pub fn queue_block(&mut self, block: Block, height: u32) {
        self.pending_blocks.push((block, height));
    }

    /// Process all pending blocks
    pub fn process_pending_blocks(&mut self) -> usize {
        let count = self.pending_blocks.len();
        // For now, we just clear them since BDK wallet in memory 
        // doesn't have a direct "apply_block" without a chain source.
        // The real sync will happen when we connect to the node's full scan.
        self.pending_blocks.clear();
        count
    }

    /// Get list of transactions from the wallet
    pub fn get_transactions(&self) -> Vec<WalletTransaction> {
        use bdk_wallet::chain::ChainPosition;
        
        self.wallet.transactions()
            .map(|wallet_tx| {
                let tx = &wallet_tx.tx_node.tx;
                let txid = tx.compute_txid().to_string();
                let (sent, received) = self.wallet.sent_and_received(tx);
                
                let (is_confirmed, confirmation_height, timestamp) = match &wallet_tx.chain_position {
                    ChainPosition::Confirmed { anchor, .. } => {
                        (true, Some(anchor.block_id.height), None)
                    }
                    ChainPosition::Unconfirmed { last_seen, .. } => {
                        (false, None, *last_seen)
                    }
                };

                // Try to calculate fee
                let fee = self.wallet.calculate_fee(tx).ok().map(|f| f.to_sat());

                WalletTransaction {
                    txid,
                    sent: sent.to_sat(),
                    received: received.to_sat(),
                    fee,
                    is_confirmed,
                    confirmation_height,
                    timestamp,
                }
            })
            .collect()
    }

    /// Get the script pubkeys for the wallet (for registering with node)
    pub fn get_script_pubkeys(&self) -> Vec<bitcoin::ScriptBuf> {
        let mut scripts = Vec::new();
        
        // Get some addresses from external keychain
        for i in 0..20u32 {
            let info = self.wallet.peek_address(KeychainKind::External, i);
            scripts.push(info.address.script_pubkey());
        }
        
        // Get some addresses from internal keychain  
        for i in 0..20u32 {
            let info = self.wallet.peek_address(KeychainKind::Internal, i);
            scripts.push(info.address.script_pubkey());
        }
        
        scripts
    }
}

/// BlockConsumer implementation for the wallet
/// This allows the node to send blocks directly to the wallet
pub struct WalletBlockConsumer;

impl BlockConsumer for WalletBlockConsumer {
    fn on_block(
        &self,
        block: &Block,
        height: u32,
        _spent_utxos: Option<&HashMap<OutPoint, UtxoData>>,
    ) {
        // Queue block for processing
        // We use tokio::spawn to avoid blocking
        let block_clone = block.clone();
        tokio::spawn(async move {
            let mut handle = WALLET_MANAGER.write().await;
            if let Some(manager) = handle.as_mut() {
                manager.queue_block(block_clone, height);
            }
        });
    }

    fn wants_spent_utxos(&self) -> bool {
        false
    }
}
