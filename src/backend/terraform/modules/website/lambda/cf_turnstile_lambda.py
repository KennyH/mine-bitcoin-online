from __future__ import annotations

import json
import logging
import os
import urllib.error
import urllib.parse
import urllib.request
from typing import Any, Optional


# ────────────────────────────  Configuration  ─────────────────────────────── #


LOG_LEVEL: str = os.getenv("LOG_LEVEL", "INFO").upper()
TURNSTILE_SECRET_KEY: Optional[str] = os.getenv("TURNSTILE_SECRET_KEY")
TURNSTILE_VERIFY_URL = "https://challenges.cloudflare.com/turnstile/v0/siteverify"

logging.basicConfig(level=LOG_LEVEL)
logger = logging.getLogger(__name__)

COMMON_HEADERS: dict[str, str] = {
    "Content-Type": "application/json",
    "Access-Control-Allow-Headers": "Content-Type",
    "Access-Control-Allow-Methods": "POST,OPTIONS",
}

# ────────────────────────────  Helper functions  ──────────────────────────── #


def _response(status: int, body: dict[str, Any]) -> dict[str, Any]:
    """Return a payload shaped for API Gateway/Lambda proxy integration."""
    return {"statusCode": status, "headers": COMMON_HEADERS, "body": json.dumps(body)}


def _decode_body(event: dict[str, Any]) -> dict[str, Any]:
    """Gracefully handle a string or dict body."""
    raw_body = event.get("body", {})
    if isinstance(raw_body, str):
        return json.loads(raw_body or "{}")
    return raw_body


def _verify_with_turnstile(token: str, remote_ip: Optional[str]) -> dict[str, Any]:
    """POST the token to Cloudflare and return the parsed JSON response."""
    payload: dict[str, str] = {"secret": TURNSTILE_SECRET_KEY, "response": token}
    if remote_ip:
        payload["remoteip"] = remote_ip

    encoded = urllib.parse.urlencode(payload).encode()
    req = urllib.request.Request(
        TURNSTILE_VERIFY_URL,
        data=encoded,
        headers={"Content-Type": "application/x-www-form-urlencoded"},
        method="POST",
    )

    with urllib.request.urlopen(req) as resp:  # nosec B310 (urllib ok in Lambda)
        return json.loads(resp.read().decode())


# ────────────────────────────  Lambda entry‑point  ────────────────────────── #


def lambda_handler(event: dict[str, Any], context: Any) -> dict[str, Any]:
    """
    Verify a Cloudflare Turnstile token.

    Body must be JSON containing {"token": "<turnstile-response>"}.
    """
    logger.debug("Incoming event: %s", json.dumps(event))

    if not TURNSTILE_SECRET_KEY:
        logger.error("TURNSTILE_SECRET_KEY is not set")
        return _response(500, {"message": "Internal server error"})

    try:
        body = _decode_body(event)
        token: str | None = body.get("token")
        if not token:
            logger.warning("No token provided")
            return _response(400, {"message": "Token is required"})

        remote_ip: Optional[str] = (
            event.get("requestContext", {}).get("http", {}).get("sourceIp")
        )

        logger.info("Verifying token %s… ip=%s", token[:5], remote_ip)

        result = _verify_with_turnstile(token, remote_ip)

        if result.get("success"):
            return _response(200, {"success": True, "message": "Token verified"})

        return _response(
            400,
            {
                "success": False,
                "message": "Token verification failed",
                "error_codes": result.get("error-codes", []),
            },
        )

    except json.JSONDecodeError:
        logger.warning("Malformed JSON body")
        return _response(400, {"message": "Invalid JSON body"})

    except urllib.error.URLError as err:
        logger.error("Turnstile verification call failed: %s", err)
        return _response(502, {"message": "Verification service unreachable"})

    except Exception:
        logger.exception("Unhandled exception")
        return _response(500, {"message": "Internal server error"})

