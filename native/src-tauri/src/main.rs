#![cfg_attr(not(debug_assertions), windows_subsystem = "windows")]

mod server;

use std::sync::{Arc, Mutex};
use std::path::PathBuf;
use server::{ServerState, SharedServerState, start_server, stop_server, is_server_running, get_server_url, trigger_reload};

#[tauri::command]
async fn start_axum_server(state: tauri::State<'_, SharedServerState>) -> Result<String, String> {
    start_server(state.inner().clone()).await?;
    Ok("Serveur démarré avec succès".to_string())
}

#[tauri::command]
async fn stop_axum_server(state: tauri::State<'_, SharedServerState>) -> Result<String, String> {
    stop_server(state.inner().clone()).await?;
    Ok("Serveur arrêté avec succès".to_string())
}

#[tauri::command]
fn check_server_status(state: tauri::State<'_, SharedServerState>) -> bool {
    is_server_running(state.inner())
}

#[tauri::command]
fn get_server_address(state: tauri::State<'_, SharedServerState>) -> String {
    get_server_url(state.inner())
}

#[tauri::command]
async fn trigger_manual_reload(state: tauri::State<'_, SharedServerState>) -> Result<String, String> {
    trigger_reload(state.inner().clone()).await?;
    Ok("Rechargement déclenché".to_string())
}

fn main() {
    // Déterminer le chemin vers le dossier build (assets)
    let assets_dir = get_assets_dir();
    println!("Dossier des assets: {:?}", assets_dir);

    // Créer l'état partagé (serveur sur le port 3000)
    let server_state = Arc::new(Mutex::new(ServerState::new(3000, assets_dir)));

    tauri::Builder::default()
        .manage(server_state)
        .invoke_handler(tauri::generate_handler![
            start_axum_server,
            stop_axum_server,
            check_server_status,
            get_server_address,
            trigger_manual_reload
        ])
        .plugin(tauri_plugin_opener::init())
        .run(tauri::generate_context!())
        .expect("error while running tauri application");
}

// Fonction pour déterminer le chemin des assets
fn get_assets_dir() -> PathBuf {
    // En développement, le chemin est relatif au répertoire actuel
    let dev_path = PathBuf::from("../../build");

    if dev_path.exists() {
        return dev_path;
    }

    // Si on est en production, utiliser le chemin de l'application
    if let Ok(exe_path) = std::env::current_exe() {
        if let Some(exe_dir) = exe_path.parent() {
            // Vérifier différentes possibilités pour le chemin des assets
            for path in [
                exe_dir.join("build"),
                exe_dir.join("../build"),
                exe_dir.join("../../build"),
            ] {
                if path.exists() {
                    return path;
                }
            }
        }
    }

    // Par défaut, utiliser le chemin de développement
    dev_path
}