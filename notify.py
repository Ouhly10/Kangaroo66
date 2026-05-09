#!/usr/bin/env python3
# ============================================================
# notify.py - Telegram Notification Script for Kangaroo
# ============================================================

import argparse
import requests
import sys

def send_message(token: str, chat_id: str, message: str) -> bool:
    url = f"https://api.telegram.org/bot{token}/sendMessage"
    payload = {
        "chat_id": chat_id,
        "text": message,
        "parse_mode": "Markdown"
    }
    try:
        resp = requests.post(url, json=payload, timeout=15)
        resp.raise_for_status()
        print(f"[Telegram] ✓ تم الإرسال")
        return True
    except requests.exceptions.RequestException as e:
        print(f"[Telegram] ✗ فشل الإرسال: {e}", file=sys.stderr)
        return False

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Telegram Notifier")
    parser.add_argument("--token",  required=True, help="Telegram Bot Token")
    parser.add_argument("--chat",   required=True, help="Telegram Chat ID")
    parser.add_argument("--msg",    required=True, help="الرسالة")
    args = parser.parse_args()

    success = send_message(args.token, args.chat, args.msg)
    sys.exit(0 if success else 1)
