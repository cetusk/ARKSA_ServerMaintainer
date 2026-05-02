//! steamcmd wrapper. Replaces the upstream batch scripts:
//!
//!   AsaServerManegerWin_steamcmd_dl.bat → `ensure_steamcmd`
//!   AsaServerManegerWin_asa_dl.bat       → `install_or_update_server`
//!
//! `ensure_steamcmd` downloads `steamcmd.zip` from the official Valve CDN if
//! a local copy is not already present and unpacks it. `install_or_update_server`
//! shells out to the steamcmd binary with the standard non-interactive flag
//! sequence used by ARK admins.

use std::fs;
use std::io::{BufRead, BufReader};
use std::path::{Path, PathBuf};
use std::process::{Command, Stdio};
use std::sync::mpsc;
use std::thread;
use std::time::Duration;

use crate::error::{Error, Result};
use crate::ARK_SA_APPID;

/// Official steamcmd download URL.
pub const STEAMCMD_ZIP_URL: &str =
    "https://steamcdn-a.akamaihd.net/client/installer/steamcmd.zip";

/// Subdirectory name used by upstream and by us.
pub const STEAMCMD_DIRNAME: &str = "steamcmd";
pub const STEAMCMD_EXE: &str = "steamcmd.exe";

/// Time we'll wait for the entire HTTP download.
const DOWNLOAD_TIMEOUT: Duration = Duration::from_secs(120);

/// Ensure `<base>/steamcmd/steamcmd.exe` exists; download + extract on demand.
/// Returns the absolute path to `steamcmd.exe`.
///
/// The first time you run a freshly-extracted steamcmd it self-updates and
/// then exits — we trigger that here too so the caller does not have to.
pub fn ensure_steamcmd(base: impl AsRef<Path>) -> Result<PathBuf> {
    let dir = base.as_ref().join(STEAMCMD_DIRNAME);
    let exe = dir.join(STEAMCMD_EXE);
    if exe.exists() {
        return Ok(exe);
    }

    fs::create_dir_all(&dir)?;
    let zip_path = dir.join("steamcmd.zip");
    download_to(STEAMCMD_ZIP_URL, &zip_path)?;
    extract_zip(&zip_path, &dir)?;
    let _ = fs::remove_file(&zip_path);

    if !exe.exists() {
        return Err(Error::Other(format!(
            "steamcmd extraction produced no executable at {}",
            exe.display()
        )));
    }

    // First run primes/updates steamcmd itself.
    let _ = Command::new(&exe)
        .arg("+quit")
        .current_dir(&dir)
        .stdout(Stdio::null())
        .stderr(Stdio::null())
        .status();

    Ok(exe)
}

/// Run `steamcmd +force_install_dir <install_dir> +login anonymous
/// +app_update <ARK_SA_APPID> +quit` and stream every output line through
/// `on_log`. Returns when steamcmd exits.
///
/// `on_log` is invoked from a background reader thread; keep it cheap and
/// thread-safe. It receives one line of stdout/stderr at a time, with no
/// trailing newline.
pub fn install_or_update_server<F>(
    steamcmd_exe: &Path,
    install_dir: &Path,
    on_log: F,
) -> Result<i32>
where
    F: FnMut(&str) + Send + 'static,
{
    fs::create_dir_all(install_dir)?;
    let install_arg = install_dir
        .to_str()
        .ok_or_else(|| Error::Other("install_dir is not valid UTF-8".into()))?;

    let mut child = Command::new(steamcmd_exe)
        .arg("+force_install_dir")
        .arg(install_arg)
        .arg("+login")
        .arg("anonymous")
        .arg("+app_update")
        .arg(ARK_SA_APPID.to_string())
        .arg("+quit")
        .stdout(Stdio::piped())
        .stderr(Stdio::piped())
        .spawn()?;

    pump_lines(child.stdout.take(), child.stderr.take(), on_log);

    let status = child.wait()?;
    Ok(status.code().unwrap_or(-1))
}

// ---- helpers --------------------------------------------------------------

fn download_to(url: &str, dest: &Path) -> Result<()> {
    let client = reqwest::blocking::Client::builder()
        .timeout(DOWNLOAD_TIMEOUT)
        .build()
        .map_err(|e| Error::Other(format!("reqwest client: {e}")))?;
    let mut response = client
        .get(url)
        .send()
        .map_err(|e| Error::Other(format!("download {url}: {e}")))?;
    if !response.status().is_success() {
        return Err(Error::Other(format!(
            "download {url}: HTTP {}",
            response.status()
        )));
    }
    let mut file = fs::File::create(dest)?;
    response
        .copy_to(&mut file)
        .map_err(|e| Error::Other(format!("write {}: {e}", dest.display())))?;
    Ok(())
}

fn extract_zip(zip_path: &Path, dest_dir: &Path) -> Result<()> {
    let file = fs::File::open(zip_path)?;
    let mut archive = zip::ZipArchive::new(file)
        .map_err(|e| Error::Other(format!("open zip {}: {e}", zip_path.display())))?;
    for i in 0..archive.len() {
        let mut entry = archive
            .by_index(i)
            .map_err(|e| Error::Other(format!("zip entry {i}: {e}")))?;
        let Some(rel) = entry.enclosed_name() else {
            continue;
        };
        let out_path = dest_dir.join(rel);
        if entry.is_dir() {
            fs::create_dir_all(&out_path)?;
            continue;
        }
        if let Some(parent) = out_path.parent() {
            fs::create_dir_all(parent)?;
        }
        let mut out_file = fs::File::create(&out_path)?;
        std::io::copy(&mut entry, &mut out_file)?;
    }
    Ok(())
}

/// Spawn two reader threads — one each for stdout/stderr — that forward lines
/// to `on_log` via an mpsc channel + dispatcher thread, so callbacks fire in a
/// well-defined single-threaded order.
fn pump_lines<O, E, F>(stdout: Option<O>, stderr: Option<E>, mut on_log: F)
where
    O: std::io::Read + Send + 'static,
    E: std::io::Read + Send + 'static,
    F: FnMut(&str) + Send + 'static,
{
    let (tx, rx) = mpsc::channel::<String>();

    if let Some(out) = stdout {
        let tx = tx.clone();
        thread::spawn(move || forward_lines(out, tx));
    }
    if let Some(err) = stderr {
        let tx = tx.clone();
        thread::spawn(move || forward_lines(err, tx));
    }
    drop(tx);

    thread::spawn(move || {
        for line in rx {
            on_log(&line);
        }
    });
}

fn forward_lines<R: std::io::Read>(reader: R, tx: mpsc::Sender<String>) {
    let buf = BufReader::new(reader);
    for line in buf.lines().map_while(std::result::Result::ok) {
        if tx.send(line).is_err() {
            break;
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn ensure_steamcmd_returns_existing_path() {
        // Pre-create the directory layout and a fake steamcmd.exe so we hit
        // the early-return branch without touching the network.
        let tmp = std::env::temp_dir().join(format!(
            "arksa_steamcmd_test_{}",
            std::process::id()
        ));
        let _ = fs::remove_dir_all(&tmp);
        fs::create_dir_all(tmp.join(STEAMCMD_DIRNAME)).unwrap();
        let fake = tmp.join(STEAMCMD_DIRNAME).join(STEAMCMD_EXE);
        fs::write(&fake, b"").unwrap();

        let resolved = ensure_steamcmd(&tmp).unwrap();
        assert_eq!(resolved, fake);
        let _ = fs::remove_dir_all(tmp);
    }
}
