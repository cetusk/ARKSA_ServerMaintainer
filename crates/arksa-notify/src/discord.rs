//! Discord Webhook sender. Replaces `discord.pas`.
//!
//! Strategy: a single tokio task owns an mpsc receiver; callers fire
//! `Webhook::send(...)` which enqueues a request and returns immediately.
//! Per-message templates (server starting / online / stopped / crashed /
//! ASASM update / Server-app update) live in this module.

// TODO Phase 6: implement.
