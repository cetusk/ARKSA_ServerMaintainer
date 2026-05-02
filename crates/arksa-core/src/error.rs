use std::io;

#[derive(Debug, thiserror::Error)]
pub enum Error {
    #[error("I/O error: {0}")]
    Io(#[from] io::Error),

    #[error("INI error: {0}")]
    Ini(#[from] ini::Error),

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
