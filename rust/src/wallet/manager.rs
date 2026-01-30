use std::path::Path;
use std::sync::Arc;
use tokio::sync::RwLock;
use once_cell::sync::Lazy;
use bitcoin::Network;
use bitcoin::bip32::{Xpriv, DerivationPath};
use bitcoin::secp256k1::Secp256k1;
use bdk_wallet::{Wallet, KeychainKind};
use bip39::Mnemonic;
use std::fs;
use std::str::FromStr;
use rand::RngCore;

pub static WALLET_MANAGER: Lazy<Arc<RwLock<Option<WalletManager>>>> = 
    Lazy::new(|| Arc::new(RwLock::new(None)));

pub struct WalletManager {
    pub wallet: Wallet,
    pub network: Network,
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
        })
    }

    pub fn get_balance(&self) -> u64 {
        self.wallet.balance().total().to_sat()
    }

    pub fn get_address(&mut self) -> String {
        self.wallet.reveal_next_address(KeychainKind::External).address.to_string()
    }
}
