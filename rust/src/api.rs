use std::sync::Arc;
use tokio::sync::RwLock;
use tokio::runtime::Handle;
use once_cell::sync::Lazy;
use bitcoin::Network;
use bdk_floresta::UtreexoNodeConfig;
use crate::node::control::{start_node, stop_node};
use crate::node::stats_fetcher::fetch_stats;
use crate::node::message::NodeMessage;
use crate::wallet::manager::{WALLET_MANAGER, WalletManager};

#[derive(Debug, Clone)]
pub struct WalletInfo {
    pub balance_sats: u64,
    pub address: String,
}

static NODE_HANDLE: Lazy<Arc<RwLock<Option<Arc<RwLock<bdk_floresta::Node>>>>>> = 
    Lazy::new(|| Arc::new(RwLock::new(None)));

#[flutter_rust_bridge::frb(init)]
pub fn init_app() {
    flutter_rust_bridge::setup_default_user_utils();
}

pub async fn start_node_service(data_dir: String, network: String) -> Result<(), String> {
    let mut handle = NODE_HANDLE.write().await;
    if handle.is_some() {
        return Err("Node already running".to_string());
    }

    let network = match network.to_lowercase().as_str() {
        "bitcoin" => Network::Bitcoin,
        "testnet" | "testnet3" => Network::Testnet,
        "signet" => Network::Signet,
        "regtest" => Network::Regtest,
        _ => return Err("Invalid network".to_string()),
    };

    let config = UtreexoNodeConfig {
        network,
        datadir: data_dir.clone(),
        ..Default::default()
    };

    match start_node(config).await {
        Ok(node) => {
            *handle = Some(node);
            
            // Initialize wallet
            let mut wallet_handle = WALLET_MANAGER.write().await;
            match WalletManager::init(&data_dir, network) {
                Ok(manager) => {
                    *wallet_handle = Some(manager);
                    Ok(())
                }
                Err(e) => Err(format!("Wallet init error: {}", e)),
            }
        }
        Err(e) => Err(e),
    }
}

pub async fn stop_node_service() -> Result<(), String> {
    let mut handle = NODE_HANDLE.write().await;
    if let Some(node) = handle.take() {
        match stop_node(node).await {
            Ok(_) => Ok(()),
            Err(e) => Err(e),
        }
    } else {
        Ok(())
    }
}

pub async fn is_node_running() -> bool {
    NODE_HANDLE.read().await.is_some()
}

#[derive(Debug, Clone)]
pub struct PeerDetailedInfo {
    pub address: String,
    pub user_agent: String,
    pub height: u32,
    pub is_inbound: bool,
}

#[derive(Debug, Clone)]
pub struct NodeStats {
    pub in_ibd: bool,
    pub headers: u32,
    pub blocks: u32,
    pub user_agent: String,
    pub uptime_secs: u64,
    pub peers_count: usize,
    pub peers: Vec<PeerDetailedInfo>,
}

pub async fn get_node_stats() -> Option<NodeStats> {
    let handle = NODE_HANDLE.read().await;
    if let Some(node) = handle.as_ref() {
        if let NodeMessage::Statistics(stats) = fetch_stats(node.clone(), None).await {
            let peers = stats.peer_informations.iter().map(|p| {
                PeerDetailedInfo {
                    address: p.socket.to_string(),
                    user_agent: p.user_agent.clone(),
                    height: p.initial_height,
                    is_inbound: !matches!(p.connection_kind, bdk_floresta::ConnectionKind::Feeler),
                }
            }).collect();

            return Some(NodeStats {
                in_ibd: stats.in_ibd,
                headers: stats.headers,
                blocks: stats.blocks,
                user_agent: stats.user_agent,
                uptime_secs: stats.uptime.as_secs(),
                peers_count: stats.peer_informations.len(),
                peers,
            });
        }
    }
    None
}
pub async fn get_wallet_info() -> Option<WalletInfo> {
    let mut handle: tokio::sync::RwLockWriteGuard<'_, Option<WalletManager>> = WALLET_MANAGER.write().await;
    if let Some(manager) = handle.as_mut() {
        return Some(WalletInfo {
            balance_sats: manager.get_balance(),
            address: manager.get_address(),
        });
    }
    None
}

/// Transaction info for Flutter
#[derive(Debug, Clone)]
pub struct WalletTransactionInfo {
    pub txid: String,
    pub sent: u64,
    pub received: u64,
    pub fee: Option<u64>,
    pub is_confirmed: bool,
    pub confirmation_height: Option<u32>,
    pub timestamp: Option<u64>,
}

/// Get wallet transactions
pub async fn get_wallet_transactions() -> Vec<WalletTransactionInfo> {
    let handle = WALLET_MANAGER.read().await;
    if let Some(manager) = handle.as_ref() {
        return manager.get_transactions()
            .into_iter()
            .map(|tx| WalletTransactionInfo {
                txid: tx.txid,
                sent: tx.sent,
                received: tx.received,
                fee: tx.fee,
                is_confirmed: tx.is_confirmed,
                confirmation_height: tx.confirmation_height,
                timestamp: tx.timestamp,
            })
            .collect();
    }
    Vec::new()
}

/// Sync wallet - process pending blocks from the node
pub async fn sync_wallet() -> Result<u32, String> {
    let mut handle = WALLET_MANAGER.write().await;
    if let Some(manager) = handle.as_mut() {
        let processed = manager.process_pending_blocks();
        return Ok(processed as u32);
    }
    Err("Wallet not initialized".to_string())
}


/// Check if a wallet already exists in the data directory
pub fn check_wallet_exists(data_dir: String) -> bool {
    let mnemonic_path = std::path::Path::new(&data_dir).join("mnemonic.txt");
    mnemonic_path.exists()
}

/// Create a new wallet and return the mnemonic phrase
pub fn create_wallet_mnemonic(data_dir: String) -> Result<String, String> {
    let mnemonic_path = std::path::Path::new(&data_dir).join("mnemonic.txt");
    
    if mnemonic_path.exists() {
        return Err("Wallet already exists".to_string());
    }
    
    // Generate 16 bytes of entropy for 12-word mnemonic
    let mut entropy = [0u8; 16];
    rand::RngCore::fill_bytes(&mut rand::rng(), &mut entropy);
    let mnemonic = bip39::Mnemonic::from_entropy(&entropy)
        .map_err(|e| format!("Failed to create mnemonic: {}", e))?;
    
    // Create directory if it doesn't exist
    std::fs::create_dir_all(&data_dir)
        .map_err(|e| format!("Failed to create data dir: {}", e))?;
    
    // Save mnemonic to file
    std::fs::write(&mnemonic_path, mnemonic.to_string())
        .map_err(|e| format!("Failed to save mnemonic: {}", e))?;
    
    Ok(mnemonic.to_string())
}

/// Import an existing mnemonic phrase
pub fn import_wallet_mnemonic(data_dir: String, mnemonic: String) -> Result<(), String> {
    let mnemonic_path = std::path::Path::new(&data_dir).join("mnemonic.txt");
    
    // Validate the mnemonic
    let _ = bip39::Mnemonic::parse(mnemonic.trim())
        .map_err(|e| format!("Invalid mnemonic: {}", e))?;
    
    // Create directory if it doesn't exist
    std::fs::create_dir_all(&data_dir)
        .map_err(|e| format!("Failed to create data dir: {}", e))?;
    
    // Save mnemonic to file
    std::fs::write(&mnemonic_path, mnemonic.trim())
        .map_err(|e| format!("Failed to save mnemonic: {}", e))?;
    
    Ok(())
}

/// Get the stored mnemonic phrase (for backup display)
pub fn get_wallet_mnemonic(data_dir: String) -> Option<String> {
    let mnemonic_path = std::path::Path::new(&data_dir).join("mnemonic.txt");
    std::fs::read_to_string(mnemonic_path).ok()
}
