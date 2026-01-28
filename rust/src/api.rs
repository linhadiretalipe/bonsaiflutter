use flutter_rust_bridge::frb;

#[frb(sync)] // Synchronous return for simplicity
pub fn greet(name: String) -> String {
    format!("Hello, {}! This is Bonsai Mobile via Rust.", name)
}

#[frb(init)]
pub fn init_app() {
    // Default handler for logging
    flutter_rust_bridge::setup_default_user_utils();
}
