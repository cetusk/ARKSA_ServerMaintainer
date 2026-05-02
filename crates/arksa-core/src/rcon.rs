//! Source RCON protocol client. Ported from the original `rcon.pas`.
//!
//! Wire format (little-endian):
//!   i32 size, i32 id, i32 type, body (NUL-terminated), NUL pad
//!
//! Types:
//!   3 = SERVERDATA_AUTH
//!   2 = SERVERDATA_AUTH_RESPONSE / SERVERDATA_EXECCOMMAND
//!   0 = SERVERDATA_RESPONSE_VALUE / SERVERDATA_CHECK

// TODO Phase 2: implement TCP client (tokio) + auth + command exchange.
