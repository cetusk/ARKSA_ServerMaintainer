//! Discord Webhook sender (synchronous, single-shot).
//!
//! Replaces upstream `discord.pas`. The original used a long-lived async
//! sender thread; we keep things simple by spawning a regular OS thread per
//! call from the GUI side and doing a blocking POST here.

use std::time::Duration;

use anyhow::{anyhow, Result};

const SEND_TIMEOUT: Duration = Duration::from_secs(5);

/// POST a message to a Discord webhook. `content` is sent as the message
/// body (Discord's `content` field; up to 2000 characters).
pub fn send(webhook_url: &str, content: &str) -> Result<()> {
    if webhook_url.trim().is_empty() {
        return Err(anyhow!("webhook URL is empty"));
    }
    let client = reqwest::blocking::Client::builder()
        .timeout(SEND_TIMEOUT)
        .build()?;
    // Discord truncates anything beyond 2000 characters silently; we trim
    // here so the payload always fits.
    let body = serde_json::json!({
        "content": truncate(content, 1990),
    });
    let response = client
        .post(webhook_url)
        .json(&body)
        .send()
        .map_err(|e| anyhow!("send: {e}"))?;
    if !response.status().is_success() {
        return Err(anyhow!("Discord: HTTP {}", response.status()));
    }
    Ok(())
}

fn truncate(s: &str, max_chars: usize) -> String {
    if s.chars().count() <= max_chars {
        s.to_string()
    } else {
        let mut out: String = s.chars().take(max_chars - 1).collect();
        out.push('…');
        out
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn empty_url_is_rejected() {
        assert!(send("", "x").is_err());
        assert!(send("   ", "x").is_err());
    }

    #[test]
    fn truncate_caps_long_text() {
        let s = "a".repeat(2500);
        let t = truncate(&s, 1990);
        assert_eq!(t.chars().count(), 1990);
        assert!(t.ends_with('…'));
    }

    #[test]
    fn truncate_passes_short_text() {
        assert_eq!(truncate("hello", 100), "hello");
    }
}
