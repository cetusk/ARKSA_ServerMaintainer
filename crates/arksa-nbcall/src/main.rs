//! arksa-nbcall
//!
//! Replacement for upstream `NBCall.exe`. Runs a child command attached to a
//! Windows pseudo console (ConPTY) and forwards stdin/stdout. Used by the GUI
//! to invoke external CLI tools whose output is needed verbatim (e.g. fetching
//! the ARK dedicated server's latest BuildID).
//!
//! Phase 0: stub. Phase 1+ will implement the ConPTY pipeline using
//! `windows::Win32::System::Console::CreatePseudoConsole`.

use anyhow::{bail, Result};
use std::env;

fn main() -> Result<()> {
    let args: Vec<String> = env::args().collect();
    if args.len() < 2 {
        bail!("Usage: arksa-nbcall <command> [args...]");
    }
    // TODO Phase 1: implement ConPTY launcher (ports `NBCall.lpr`).
    eprintln!("arksa-nbcall (Phase 0 stub): would run: {:?}", &args[1..]);
    Ok(())
}
