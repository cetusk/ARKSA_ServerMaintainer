//! Source RCON protocol client. Ported from upstream `rcon.pas`.
//!
//! Wire format (little-endian, all ints i32):
//!   [size][id][type][body bytes][\0][\0]
//! `size` covers everything *except itself*, so size = 10 + len(body):
//!   4 (id) + 4 (type) + N (body) + 1 (string NUL) + 1 (packet NUL) = 10 + N
//!
//! Packet types:
//!   3 = SERVERDATA_AUTH               (client → server, auth request)
//!   2 = SERVERDATA_AUTH_RESPONSE      (server → client, auth result; id == -1 = fail)
//!   2 = SERVERDATA_EXECCOMMAND        (client → server, run command)
//!   0 = SERVERDATA_RESPONSE_VALUE     (server → client, command output)
//!
//! Each `RconClient::execute` opens a fresh TCP connection, authenticates,
//! sends one command, reads one response, and disconnects. This matches
//! upstream's per-call semantics and keeps the implementation small.
//!
//! Multi-packet responses (>4096 bytes) are *not* yet handled; almost all ARK
//! commands a personal-server admin sends (SaveWorld, DoExit, Broadcast,
//! ListPlayers on a small lobby) fit comfortably in one packet. We can revisit
//! the "mirror packet" trick if a real use case appears.

use std::io::{Read, Write};
use std::net::{SocketAddr, TcpStream, ToSocketAddrs};
use std::time::Duration;

use crate::error::{Error, Result};

const TYPE_AUTH: i32 = 3;
const TYPE_AUTH_RESPONSE: i32 = 2;
const TYPE_EXECCOMMAND: i32 = 2;
const TYPE_RESPONSE_VALUE: i32 = 0;

/// Maximum packet size the Source RCON spec allows.
const MAX_PACKET_BYTES: usize = 4096;
/// Maximum body bytes a single sent command may contain.
/// 4096 - 14 (4 size + 4 id + 4 type + 2 trailing NULs) = 4082, matching
/// upstream's `Length(cmd) >= 4096 - 14` guard.
const MAX_COMMAND_BYTES: usize = MAX_PACKET_BYTES - 14;

const DEFAULT_TIMEOUT: Duration = Duration::from_secs(5);

#[derive(Debug, Clone)]
pub struct RconClient {
    addr: SocketAddr,
    password: String,
    timeout: Duration,
}

#[derive(Debug, Clone)]
pub struct RconResponse {
    /// Decoded response body. Trailing NULs stripped, line endings preserved.
    pub body: String,
    pub packet_id: i32,
}

impl RconClient {
    pub fn new(addr: SocketAddr, password: impl Into<String>) -> Self {
        Self {
            addr,
            password: password.into(),
            timeout: DEFAULT_TIMEOUT,
        }
    }

    /// Convenience constructor that resolves "host:port".
    pub fn connect(host: &str, port: u16, password: impl Into<String>) -> Result<Self> {
        let addr = (host, port)
            .to_socket_addrs()?
            .next()
            .ok_or_else(|| Error::Other(format!("could not resolve {host}:{port}")))?;
        Ok(Self::new(addr, password))
    }

    pub fn with_timeout(mut self, timeout: Duration) -> Self {
        self.timeout = timeout;
        self
    }

    /// One-shot: open → auth → send command → read response → close.
    pub fn execute(&self, command: &str) -> Result<RconResponse> {
        if command.is_empty() {
            return Err(Error::RconCommandEmpty);
        }
        if command.len() > MAX_COMMAND_BYTES {
            return Err(Error::RconPacketTooLarge);
        }
        if self.password.is_empty() {
            return Err(Error::RconProtocol("RCON password is empty".into()));
        }

        let mut stream = TcpStream::connect_timeout(&self.addr, self.timeout)?;
        stream.set_read_timeout(Some(self.timeout))?;
        stream.set_write_timeout(Some(self.timeout))?;
        stream.set_nodelay(true)?;

        // Random-ish, but deterministic enough — we just need to reliably
        // distinguish our reply from the magic -1 that signals auth failure.
        let auth_id: i32 = (std::process::id() as i32 ^ 0x6B65_7973) & 0x0FFF_FFFF;
        let cmd_id: i32 = auth_id.wrapping_add(1);

        // ── auth ───────────────────────────────────────────────────────
        write_packet(&mut stream, auth_id, TYPE_AUTH, self.password.as_bytes())?;
        // Some servers reply with an empty SERVERDATA_RESPONSE_VALUE before
        // the actual auth response; loop until we see the real one.
        loop {
            let pkt = read_packet(&mut stream)?;
            if pkt.packet_type == TYPE_AUTH_RESPONSE {
                if pkt.id == -1 {
                    return Err(Error::RconAuthFailed);
                }
                if pkt.id != auth_id {
                    return Err(Error::RconProtocol(format!(
                        "auth response id mismatch: expected {auth_id}, got {}",
                        pkt.id
                    )));
                }
                break;
            }
            // Otherwise discard intermediate packets and keep reading.
        }

        // ── command ───────────────────────────────────────────────────
        write_packet(&mut stream, cmd_id, TYPE_EXECCOMMAND, command.as_bytes())?;
        let response = loop {
            let pkt = read_packet(&mut stream)?;
            if pkt.packet_type != TYPE_RESPONSE_VALUE {
                continue;
            }
            if pkt.id != cmd_id {
                continue;
            }
            break pkt;
        };

        // Drop trailing NULs and any control NULs the server may have padded.
        let body = String::from_utf8_lossy(&response.body)
            .trim_end_matches('\0')
            .to_string();

        Ok(RconResponse {
            body,
            packet_id: response.id,
        })
    }
}

// ---- packet I/O -----------------------------------------------------------

#[derive(Debug)]
struct RawPacket {
    id: i32,
    packet_type: i32,
    body: Vec<u8>,
}

fn write_packet(stream: &mut TcpStream, id: i32, packet_type: i32, body: &[u8]) -> Result<()> {
    // size field covers id (4) + type (4) + body + NUL string term (1) + NUL packet term (1)
    let size: i32 = (10 + body.len()) as i32;
    let mut buf = Vec::with_capacity(4 + size as usize);
    buf.extend_from_slice(&size.to_le_bytes());
    buf.extend_from_slice(&id.to_le_bytes());
    buf.extend_from_slice(&packet_type.to_le_bytes());
    buf.extend_from_slice(body);
    buf.push(0);
    buf.push(0);
    stream.write_all(&buf)?;
    stream.flush()?;
    Ok(())
}

fn read_packet(stream: &mut TcpStream) -> Result<RawPacket> {
    let mut size_buf = [0u8; 4];
    stream.read_exact(&mut size_buf)?;
    let size = i32::from_le_bytes(size_buf);

    if !(10..=MAX_PACKET_BYTES as i32).contains(&size) {
        return Err(Error::RconProtocol(format!(
            "packet size out of range: {size}"
        )));
    }

    let mut payload = vec![0u8; size as usize];
    stream.read_exact(&mut payload)?;

    let id = i32::from_le_bytes([payload[0], payload[1], payload[2], payload[3]]);
    let packet_type = i32::from_le_bytes([payload[4], payload[5], payload[6], payload[7]]);
    // Body sits between byte 8 and the two trailing NULs.
    let body = if payload.len() >= 10 {
        payload[8..payload.len() - 2].to_vec()
    } else {
        Vec::new()
    };

    Ok(RawPacket {
        id,
        packet_type,
        body,
    })
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::io::Cursor;

    /// Round-trip a packet through the framing logic by writing to an in-memory
    /// buffer and re-parsing the bytes. We re-implement the stream interaction
    /// against `Cursor<Vec<u8>>` so the test does not need a real TCP socket.
    #[test]
    fn packet_framing_roundtrip() {
        let body = b"hello world";
        let mut buf = Vec::new();
        let size: i32 = (10 + body.len()) as i32;
        buf.extend_from_slice(&size.to_le_bytes());
        buf.extend_from_slice(&42i32.to_le_bytes());
        buf.extend_from_slice(&TYPE_RESPONSE_VALUE.to_le_bytes());
        buf.extend_from_slice(body);
        buf.push(0);
        buf.push(0);

        let mut cursor = Cursor::new(buf);
        let mut size_field = [0u8; 4];
        cursor.read_exact(&mut size_field).unwrap();
        assert_eq!(i32::from_le_bytes(size_field), size);

        let mut payload = vec![0u8; size as usize];
        cursor.read_exact(&mut payload).unwrap();
        let id = i32::from_le_bytes([payload[0], payload[1], payload[2], payload[3]]);
        let typ = i32::from_le_bytes([payload[4], payload[5], payload[6], payload[7]]);
        let parsed_body = &payload[8..payload.len() - 2];
        assert_eq!(id, 42);
        assert_eq!(typ, TYPE_RESPONSE_VALUE);
        assert_eq!(parsed_body, body);
    }

    #[test]
    fn rejects_empty_command() {
        let client = RconClient::new(
            "127.0.0.1:27020".parse().unwrap(),
            "pw",
        );
        assert!(matches!(client.execute(""), Err(Error::RconCommandEmpty)));
    }

    #[test]
    fn rejects_too_large_command() {
        let client = RconClient::new(
            "127.0.0.1:27020".parse().unwrap(),
            "pw",
        );
        let huge = "a".repeat(MAX_COMMAND_BYTES + 1);
        assert!(matches!(
            client.execute(&huge),
            Err(Error::RconPacketTooLarge)
        ));
    }

    #[test]
    fn rejects_empty_password() {
        let client = RconClient::new("127.0.0.1:27020".parse().unwrap(), "");
        assert!(matches!(
            client.execute("ListPlayers"),
            Err(Error::RconProtocol(_))
        ));
    }
}
