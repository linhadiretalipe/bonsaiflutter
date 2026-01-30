use core::fmt::Display;
use std::collections::HashMap;
use std::net::SocketAddr;
use std::sync::Arc;
use std::time::Duration;
use std::time::Instant;

use bdk_floresta::BlockConsumer;
use bdk_floresta::Node;
use bdk_floresta::UtreexoNodeConfig;
use bdk_floresta::UtxoData;
use bdk_floresta::builder::Builder;
use bitcoin::Block;
use bitcoin::Network;
use bitcoin::OutPoint;
// use iced::Element;
// use iced::Subscription;
// use iced::Task;
// use iced::clipboard;
use futures::SinkExt;
// use iced::widget::qr_code;
use once_cell::sync::Lazy;
use tokio::runtime::Handle;
use tokio::sync::Mutex;
use tokio::sync::RwLock;
use tokio::sync::mpsc;
use tracing::error;
use tracing::info;

// use crate::Tab;
use crate::common::util::format_thousands;
use crate::node::error::BonsaiNodeError;
use crate::node::geoip::GeoIpReader;
use crate::node::log_capture::LogCapture;
use crate::node::message::NodeMessage;
use crate::node::stats_fetcher::NodeStatistics;
use crate::node::stats_fetcher::fetch_stats;

pub const DATA_DIR: &str = "./data/";
pub const NETWORK: Network = Network::Signet;
pub const FETCH_STATISTICS_TIME: u64 = 1;

static BLOCK_RECEIVER: Lazy<Arc<Mutex<Option<mpsc::UnboundedReceiver<Block>>>>> =
    Lazy::new(|| Arc::new(Mutex::new(None)));

#[derive(Clone, Debug, Default)]
pub enum NodeStatus {
    #[default]
    Inactive,
    Starting,
    Running,
    ShuttingDown,
    #[allow(unused)]
    Failed(BonsaiNodeError),
}

impl Display for NodeStatus {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match &self {
            Self::Inactive => write!(f, "INACTIVE"),
            Self::Starting => write!(f, "STARTING"),
            Self::Running => write!(f, "RUNNING"),
            Self::ShuttingDown => write!(f, "SHUTTING DOWN"),
            Self::Failed(e) => write!(f, "FAILED [{}]", e),
        }
    }
}

pub(crate) struct BlockForwarder {
    tx: mpsc::UnboundedSender<Block>,
}

impl BlockConsumer for BlockForwarder {
    fn on_block(
        &self,
        block: &Block,
        _height: u32,
        _spent_utxos: Option<&HashMap<OutPoint, UtxoData>>,
    ) {
        let _ = self.tx.send(block.clone());
    }

    #[allow(unused)]
    fn wants_spent_utxos(&self) -> bool {
        false
    }
}

/*
#[derive(Default)]
pub(crate) struct EmbeddedNode {
    pub(crate) config: Option<UtreexoNodeConfig>,
    pub(crate) handle: Option<Arc<RwLock<Node>>>,
    pub(crate) status: NodeStatus,
    pub(crate) statistics: Option<NodeStatistics>,
    pub(crate) subscription_active: bool,
    pub(crate) is_shutting_down: bool,
    pub(crate) log_capture: LogCapture,
    pub(crate) last_log_version: usize,
    pub(crate) start_time: Option<Instant>,
    pub(crate) peer_input: String,
    pub(crate) geoip_reader: Option<GeoIpReader>,
    pub(crate) accumulator_qr_data: Option<qr_code::Data>,
    pub(crate) block_explorer_height_str: String,
    pub(crate) latest_blocks: Vec<Block>,
    pub(crate) block_explorer_current_block: Option<Block>,
    pub(crate) block_explorer_expanded_tx_idx: Option<usize>,
}

impl EmbeddedNode {
    pub fn update(&mut self, message: NodeMessage) -> Task<NodeMessage> {
        // Implementation commented out as it depends on iced
        Task::none()
    }

    pub(crate) fn subscribe(&self) -> Subscription<NodeMessage> {
        Subscription::none()
    }

    pub fn unsubscribe(&mut self) {
        self.subscription_active = false;
    }

    fn block_subscription() -> Subscription<NodeMessage> {
        Subscription::none()
    }

    pub(crate) fn view_tab(
        &self,
        tab: Tab,
        app_clock: usize,
        active_network: Network,
    ) -> Element<'_, NodeMessage> {
       unreachable!("UI code disabled for mobile")
    }
}
*/

pub(crate) async fn start_node(
    node_config: UtreexoNodeConfig,
) -> Result<Arc<RwLock<Node>>, String> {
    let rt_handle = Handle::current();

    rt_handle
        .spawn(async {
            let node = Builder::new()
                .from_config(node_config)
                .build()
                .await
                .map_err(|e| e.to_string())?;

            let (block_tx, block_rx) = mpsc::unbounded_channel();
            let forwarder = Arc::new(BlockForwarder { tx: block_tx });

            node.block_subscriber(forwarder);

            // Store receiver globally
            *BLOCK_RECEIVER.lock().await = Some(block_rx);

            Ok(Arc::new(RwLock::new(node)))
        })
        .await
        .map_err(|e| e.to_string())?
}

pub(crate) async fn stop_node(handle: Arc<RwLock<Node>>) -> Result<(), String> {
    match Arc::try_unwrap(handle) {
        Ok(lock) => {
            let node = lock.into_inner();
            node.shutdown().await.map_err(|e| e.to_string())
        }
        Err(arc) => {
            let count = Arc::strong_count(&arc);
            Err(format!("Cannot shutdown: {} references remain", count))
        }
    }
}
