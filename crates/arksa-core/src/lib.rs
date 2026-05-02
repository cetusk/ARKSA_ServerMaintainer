//! arksa-core
//!
//! ARK: Survival Ascended dedicated server control core library.
//! Houses server lifecycle, RCON protocol, Win32 process monitoring,
//! steamcmd integration, profile/settings INI handling, mod data, and backup.

pub mod backup;
pub mod error;
pub mod gamedata;
pub mod modlist;
pub mod process;
pub mod profile;
pub mod rcon;
pub mod server;
pub mod settings;
pub mod steamcmd;

pub use error::{Error, Result};

/// ARK Survival Ascended dedicated server Steam AppID.
pub const ARK_SA_APPID: u32 = 2430930;
