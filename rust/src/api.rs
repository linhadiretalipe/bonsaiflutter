use std::sync::Arc;
use tokio::sync::RwLock;
use tokio::runtime::Handle;
use once_cell::sync::Lazy;
use bitcoin::Network;
use bdk_floresta::UtreexoNodeConfig;
use crate::node::control::{start_node, stop_node};
use crate::node::stats_fetcher::fetch_stats;
use crate::node::message::NodeMessage;

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
        datadir: data_dir,
        ..Default::default()
    };

    match start_node(config).await {
        Ok(node) => {
            *handle = Some(node);
            Ok(())
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
