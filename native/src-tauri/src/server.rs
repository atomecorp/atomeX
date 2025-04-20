use std::net::SocketAddr;
use std::sync::{Arc, Mutex};
use std::path::PathBuf;
use std::process::Command;
use axum::{
    routing::get,
    Router,
    extract::State,
    extract::ws::{WebSocket, WebSocketUpgrade, Message},
};
use tower_http::services::ServeDir;
use tokio::sync::{oneshot, broadcast};
use tokio::task::JoinHandle;
use futures::{sink::SinkExt, stream::StreamExt};
use notify::{Watcher, RecursiveMode, Event};
use std::time::Duration;

// Structure for folders to watch
struct WatchConfig {
    paths: Vec<PathBuf>,
    ignore_patterns: Vec<String>,
}

// Structure to manage server state
pub struct ServerState {
    handle: Option<JoinHandle<()>>,
    shutdown_tx: Option<oneshot::Sender<()>>,
    is_running: bool,
    port: u16,
    assets_dir: PathBuf,
    reload_tx: Option<broadcast::Sender<()>>,
    watch_config: WatchConfig,
}

impl ServerState {
    pub fn new(port: u16, assets_dir: PathBuf) -> Self {
        // Configuration of folders to watch
        let watch_config = get_watch_config();

        Self {
            handle: None,
            shutdown_tx: None,
            is_running: false,
            port,
            assets_dir,
            reload_tx: None,
            watch_config,
        }
    }
}

// Function to get the configuration of folders to watch
fn get_watch_config() -> WatchConfig {
    let current_dir = std::env::current_dir().unwrap_or_else(|_| PathBuf::from("."));
    println!("Current directory: {:?}", current_dir);

    // Relative paths from the current directory
    let base_path = PathBuf::from("../..");

    // List of folders to watch
    let paths = vec![
        base_path.join("app"),
        base_path.join("sources"),
    ];

    // Patterns to ignore
    let ignore_patterns = vec![
        ".DS_Store".to_string(),
        "/build/".to_string(),
        "/build$".to_string(),
        "/build/opal/".to_string(),
    ];

    // Check and display existing paths
    for path in &paths {
        if path.exists() {
            println!("✅ Found folder to watch: {:?}", path);
        } else {
            println!("❌ Folder to watch not found: {:?}", path);
        }
    }

    WatchConfig {
        paths,
        ignore_patterns,
    }
}

// Type to share server state
pub type SharedServerState = Arc<Mutex<ServerState>>;

// Structure to pass the broadcast channel as state in Axum
#[derive(Clone)]
struct AppState {
    reload_tx: broadcast::Sender<()>,
}

// Handler for WebSocket connection for hot reload
async fn ws_handler(
    ws: WebSocketUpgrade,
    State(state): State<AppState>,
) -> axum::response::Response {
    let reload_rx = state.reload_tx.subscribe();
    ws.on_upgrade(|socket| handle_socket(socket, reload_rx))
}

// WebSocket connection management
async fn handle_socket(socket: WebSocket, mut reload_rx: broadcast::Receiver<()>) {
    let (mut sender, mut _receiver) = socket.split();

    // Task that waits for reload events and sends them to the client
    let send_task = tokio::spawn(async move {
        while let Ok(()) = reload_rx.recv().await {
            if sender.send(Message::Text("reload".to_string().into())).await.is_err() {
                break;
            }
        }
    });

    // Wait for the task to finish
    let _ = send_task.await;
}

// Check if a path should be ignored
fn should_ignore_path(path_str: &str, ignore_patterns: &[String]) -> bool {
    for pattern in ignore_patterns {
        if path_str.contains(pattern) {
           // println!("🛑 Ignoring path containing '{}': {}", pattern, path_str);
            return true;
        }
    }
    false
}

// Function to execute the refresh.sh script
fn run_refresh_script(event_path: &PathBuf) {
   // println!("🔄 Change detected in a watched folder: {:?}", event_path);

    // Get the path as a string
    let path_str = event_path.to_string_lossy();

    // Determine the folder type for the log
    let folder_type = if path_str.contains("/app/") {
        "app"
    } else if path_str.contains("/sources/") {
        "sources"
    } else {
        "unknown"
    };

    println!("📂 Watched folder involved: {}", folder_type);
    println!("📄 File path: {}", path_str);

    // Determine the path to the refresh.sh script
    let refresh_path = PathBuf::from("../../sources/helpers/refresh.sh");

    if !refresh_path.exists() {
        println!("❌ refresh.sh script not found: {:?}", refresh_path);
        return;
    }

    println!("🚀 Executing refresh.sh script");

    // Execute the script
    match Command::new("sh")
        .arg(&refresh_path)
        .arg(path_str.to_string())
        .arg(folder_type)
        .output()
    {
        Ok(output) => {
            println!("✅ Script executed successfully");
            println!("Output: {}", String::from_utf8_lossy(&output.stdout));
            if !output.stderr.is_empty() {
                println!("Errors: {}", String::from_utf8_lossy(&output.stderr));
            }
        },
        Err(e) => println!("❌ Error during execution: {:?}", e),
    }
}

// Function to set up the file watcher
fn setup_file_watcher(
    watch_config: &WatchConfig,
    reload_tx: &broadcast::Sender<()>,
) -> Result<(), String> {
    let ignore_patterns = watch_config.ignore_patterns.clone();
    let reload_sender = reload_tx.clone();

    // Create a watcher
    let mut watcher = match notify::recommended_watcher(move |res: Result<Event, notify::Error>| {
        if let Ok(event) = res {
            // Check if the change is in a watched folder
            if let Some(path) = event.paths.first() {
                let path_str = path.to_string_lossy();

                // Check if the path should be ignored
                if should_ignore_path(&path_str, &ignore_patterns) {
                    return;
                }

                // Check if the file is in a watched folder
                if path_str.contains("/app/") || path_str.contains("/sources/") {
                    println!("🎯 File modified in a watched folder: {}", path_str);

                    // Execute the refresh.sh script
                    run_refresh_script(path);

                    // Send a reload signal
                    let _ = reload_sender.send(());
                }
            }
        }
    }) {
        Ok(w) => w,
        Err(e) => return Err(format!("Error creating watcher: {:?}", e)),
    };

    // Add all folders to watch
    for path in &watch_config.paths {
        if path.exists() {
            if let Err(e) = watcher.watch(path, RecursiveMode::Recursive) {
                println!("Error watching folder {:?}: {:?}", path, e);
            } else {
                println!("Watching folder: {:?}", path);
            }
        }
    }

    // Keep the watcher alive
    tokio::spawn(async move {
        let _watcher = watcher;
        loop {
            tokio::time::sleep(Duration::from_secs(3600)).await;
        }
    });

    Ok(())
}

// Function to start the server
pub async fn start_server(state: SharedServerState) -> Result<(), String> {
    // Broadcast channel for reload events
    let (reload_tx, _) = broadcast::channel::<()>(100);

    // Configure the file watcher and other parameters from the mutex
    {
        let guard = state.lock().unwrap();

        // Check if the server is already running
        if guard.is_running {
            return Err("Server is already running".to_string());
        }

        // Configure the file watcher with a reference
        setup_file_watcher(&guard.watch_config, &reload_tx)?;
    }

    // Get parameters outside the mutex to start the server
    let port;
    let assets_dir;
    {
        let guard = state.lock().unwrap();
        port = guard.port;
        assets_dir = guard.assets_dir.clone();
    }

    let addr = SocketAddr::from(([127, 0, 0, 1], port));

    // Application state for Axum
    let app_state = AppState { reload_tx: reload_tx.clone() };

    // Create the Axum application
    let app = Router::new()
        .route("/ws", get(ws_handler))
        .fallback_service(ServeDir::new(assets_dir))
        .with_state(app_state);

    // Channel for graceful shutdown
    let (tx, rx) = oneshot::channel::<()>();

    // Start the server
    println!("Starting Axum server on http://{}", addr);
    let handle = tokio::spawn(async move {
        let listener = tokio::net::TcpListener::bind(addr).await.unwrap();

        axum::serve(listener, app)
            .with_graceful_shutdown(async {
                rx.await.ok();
                println!("Axum server stopped");
            })
            .await
            .unwrap();
    });

    // Update the state
    {
        let mut guard = state.lock().unwrap();
        guard.handle = Some(handle);
        guard.shutdown_tx = Some(tx);
        guard.reload_tx = Some(reload_tx);
        guard.is_running = true;
    }

    Ok(())
}

// Function to stop the server
pub async fn stop_server(state: SharedServerState) -> Result<(), String> {
    let mut guard = state.lock().unwrap();

    // Check if the server is running
    if !guard.is_running {
        return Err("Server is not running".to_string());
    }

    // Send the stop signal
    if let Some(tx) = guard.shutdown_tx.take() {
        let _ = tx.send(());
    }

    // Wait for the task to finish
    if let Some(handle) = guard.handle.take() {
        tokio::spawn(async move {
            let _ = handle.await;
        });
    }

    // Update the state
    guard.is_running = false;
    guard.reload_tx = None;

    Ok(())
}

// Function to check if the server is running
pub fn is_server_running(state: &SharedServerState) -> bool {
    state.lock().unwrap().is_running
}

// Function to get the server URL
pub fn get_server_url(state: &SharedServerState) -> String {
    let guard = state.lock().unwrap();
    format!("http://127.0.0.1:{}", guard.port)
}

// Function to manually trigger a reload
pub async fn trigger_reload(state: SharedServerState) -> Result<(), String> {
    let guard = state.lock().unwrap();

    if !guard.is_running {
        return Err("Server is not running".to_string());
    }

    if let Some(reload_tx) = &guard.reload_tx {
        let _ = reload_tx.send(());
        Ok(())
    } else {
        Err("Reload channel not available".to_string())
    }
}