use std::io;

#[derive(Debug, thiserror::Error)]
pub enum Error {
    #[error("I/O error: {0}")]
    Io(#[from] io::Error),

    #[error("INI parse error: {0}")]
    IniParse(String),

    // The `windows` crate itself is `#![cfg(windows)]`, so `windows::core::Error`
    // does not exist on non-Windows builds. Gate the variant accordingly.
    #[cfg(target_os = "windows")]
    #[error("Win32 error: {0}")]
    Win32(#[from] windows::core::Error),

    #[error("RCON authentication failed")]
    RconAuthFailed,

    #[error("RCON command empty")]
    RconCommandEmpty,

    #[error("RCON packet too large")]
    RconPacketTooLarge,

    #[error("RCON protocol error: {0}")]
    RconProtocol(String),

    #[error("Server process not found: {0}")]
    ServerNotRunning(String),

    #[error("Profile not found: {0}")]
    ProfileNotFound(String),

    #[error("{0}")]
    Other(String),
}

pub type Result<T> = std::result::Result<T, Error>;
