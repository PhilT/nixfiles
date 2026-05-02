//! Equivalent of lib/wallpaper.rb: download random wallpapers from Wallhaven.

use anyhow::{bail, Context, Result};
use rand::seq::SliceRandom;
use std::io::Read;

use crate::system;

const API_URL: &str = "https://wallhaven.cc/api/v1/search?sorting=random&q=lowlight&atleast=1920x1080";
const SAVE_DIR: &str = "/data/pictures/wallpaper";
const FILENAMES: [&str; 2] = ["wallpaper-left.jpg", "wallpaper-right.jpg"];

#[derive(serde::Deserialize)]
struct ApiResponse {
    data: Vec<Image>,
}

#[derive(serde::Deserialize)]
struct Image {
    path: String,
}

pub fn download(screen: Option<&str>, apply: bool, mnt: &str) -> Result<()> {
    println!("Downloading wallpapers...");
    let images = fetch_images()?;
    let urls = pick_two(&images)?;

    if matches!(screen, None | Some("left")) {
        save(&urls[0], FILENAMES[0], mnt)?;
    }
    if matches!(screen, None | Some("right")) {
        save(&urls[1], FILENAMES[1], mnt)?;
    }
    if apply {
        update_sway()?;
    }
    Ok(())
}

fn fetch_images() -> Result<Vec<Image>> {
    let body: ApiResponse = ureq::get(API_URL)
        .call()
        .context("fetching wallhaven API")?
        .into_json()
        .context("parsing wallhaven response")?;
    if body.data.is_empty() {
        bail!("No wallpaper found");
    }
    Ok(body.data)
}

fn pick_two(images: &[Image]) -> Result<Vec<String>> {
    println!("Taking a sample from {} images", images.len());
    let mut rng = rand::thread_rng();
    let picks: Vec<&Image> = images.choose_multiple(&mut rng, 2).collect();
    if picks.len() < 2 {
        bail!("Not enough wallpapers found");
    }
    Ok(picks.into_iter().map(|i| i.path.clone()).collect())
}

fn save(url: &str, filename: &str, mnt: &str) -> Result<()> {
    let resp = ureq::get(url).call().context("fetching wallpaper image")?;
    let mut bytes = Vec::new();
    resp.into_reader()
        .read_to_end(&mut bytes)
        .context("reading wallpaper body")?;

    // Naive concatenation matches Ruby File.join semantics: an empty mnt
    // leaves SAVE_DIR's leading slash intact; a non-empty mnt is prepended
    // verbatim (e.g. "/mnt" + "/data/..." = "/mnt/data/...").
    let path = format!("{mnt}{SAVE_DIR}/{filename}");
    std::fs::write(&path, &bytes).with_context(|| format!("writing {path}"))?;
    println!("Saved wallpaper to {path}");
    Ok(())
}

fn update_sway() -> Result<()> {
    let flag = "/tmp/sway-wallpaper-changing";
    std::fs::write(flag, b"")?;
    for (output, file) in [
        ("eDP-1", FILENAMES[0]),
        ("DP-2", FILENAMES[0]),
        ("DP-3", FILENAMES[1]),
    ] {
        let path = format!("{SAVE_DIR}/{file}");
        system::run_capture_quiet(&format!("swaymsg output {output} background {path} fill"))?;
    }
    std::thread::sleep(std::time::Duration::from_secs(1));
    let _ = std::fs::remove_file(flag);
    Ok(())
}
