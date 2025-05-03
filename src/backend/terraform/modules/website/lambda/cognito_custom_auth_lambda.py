from __future__ import annotations

import logging
import os
import secrets
from typing import Any

import boto3
from botocore.exceptions import ClientError

# ────────────────────────────  Configuration  ─────────────────────────────── #

LOG_LEVEL = os.getenv("LOG_LEVEL", "INFO").upper()
logging.basicConfig(level=LOG_LEVEL, force=True)
logger = logging.getLogger(__name__)

REGION = os.getenv("AWS_REGION", "us-west-2")
ses = boto3.client("ses", region_name=REGION)

FROM_EMAIL = os.getenv("FROM_EMAIL", "noreply@bitcoinbrowserminer.com")
# TODO make a static assests location
# ASSETS_BASE = os.getenv("ASSETS_BASE", "https://assets.bitcoinbrowserminer.com")
# IMG_LINK = os.getenv("IMG_LINK", f"{ASSETS_BASE}/images/bitcoin.png")
IMG_LINK = os.getenv("IMG_LINK", f"https://dev-env.bitcoinbrowserminer.com/images/bitcoin.png")

OTP_LENGTH = 6
OTP_TTL_MIN = int(os.getenv("OTP_TTL_MIN", "3"))

# ────────────────────────────  Lambda entry‑point  ────────────────────────── #


def lambda_handler(event: dict[str, Any], context: Any) -> dict[str, Any]:
    logger.info("Lambda triggered. Event: %s", event)

    trigger_source = event.get("triggerSource")
    logger.info("Trigger source: %s", trigger_source)

    trigger_handlers: dict[str, callable[[dict[str, Any], Any], dict[str, Any]]] = {
        "PreSignUp_SignUp": handle_pre_sign_up,
        "DefineAuthChallenge_Authentication": handle_define_auth_challenge,
        "CreateAuthChallenge_Authentication": handle_create_auth_challenge,
        "VerifyAuthChallengeResponse_Authentication": handle_verify_auth_challenge,
    }

    handler = trigger_handlers.get(trigger_source)
    if not handler:
        logger.warning("No handler for trigger source: %s", trigger_source)
        return event

    return handler(event, context)


# ────────────────────────────  Pre‑Sign‑Up  ───────────────────────────────── #


def handle_pre_sign_up(event: dict[str, Any], context: Any) -> dict[str, Any]:
    logger.info("PreSignUp: auto-confirming and auto-verifying user.")

    attributes = event.get("request", {}).get("userAttributes", {})
    if attributes.get("custom:tos_accepted") != "true":
        logger.warning("User did not accept ToS. Rejecting sign up.")
        raise Exception("You must accept the Terms of Service to sign up.")

    event["response"]["autoConfirmUser"] = True
    event["response"]["autoVerifyEmail"] = True
    return event


# ────────────────────────────  Define Auth Challenge  ──────────────────────── #


def handle_define_auth_challenge(
    event: dict[str, Any], context: Any
) -> dict[str, Any]:
    session = event.get("request", {}).get("session", [])
    logger.info("DefineAuthChallenge: session %s", session)

    if not session:
        logger.info("No session, issuing CUSTOM_CHALLENGE.")
        event["response"].update(
            {
                "challengeName": "CUSTOM_CHALLENGE",
                "issueTokens": False,
                "failAuthentication": False,
            }
        )
        return event

    last = session[-1]
    if (
        last.get("challengeName") == "CUSTOM_CHALLENGE"
        and last.get("challengeResult") is True
    ):
        logger.info("Previous challenge succeeded, issuing tokens.")
        event["response"].update({"issueTokens": True, "failAuthentication": False})
    else:
        logger.info("Previous challenge failed, issuing another CUSTOM_CHALLENGE.")
        event["response"].update(
            {
                "challengeName": "CUSTOM_CHALLENGE",
                "issueTokens": False,
                "failAuthentication": False,
            }
        )
    return event


# ────────────────────────────  Create Auth Challenge  ─────────────────────── #


def _one_time_code() -> str:
    return f"{secrets.randbelow(10**OTP_LENGTH):0{OTP_LENGTH}}"


def handle_create_auth_challenge(
    event: dict[str, Any], context: Any
) -> dict[str, Any]:
    logger.info("CreateAuthChallenge triggered.")

    if event["request"].get("challengeName") != "CUSTOM_CHALLENGE":
        return event

    email = event["request"].get("userAttributes", {}).get("email")
    if not email:
        logger.warning("No email in userAttributes; cannot send OTP; tell user to sign up.")
        event["response"] = {
            "publicChallengeParameters":  {"error": "NO_EMAIL"},
            "privateChallengeParameters": {},
            "challengeMetadata":          "NO_EMAIL"
        }
        return event

    code = _one_time_code()
    logger.info("Generated OTP %s-**** for %s", code[:2], email)

    event["response"]["publicChallengeParameters"] = {"email": email}
    event["response"]["privateChallengeParameters"] = {"answer": code}

    try:
        logger.info("Sending OTP code to %s", email)
        send_otp_email(code, email)
        logger.info("Email sent successfully.")
    except ClientError as exc:
        logger.error("SES error: %s", exc.response["Error"]["Message"])
    except Exception as exc:
        logger.exception("Unexpected error sending OTP: %s", exc)

    return event


# ────────────────────────────  SES Email Sender  ──────────────────────────── #


def send_otp_email(code: str, to_email: str) -> None:
    subject = "Your Bitcoin Browser Miner Login Code"
    ios_otp_line = f"{code} is your Bitcoin Browser Miner code."

    body_text = (
        f"{ios_otp_line}\n\n"
        f"Use this code to log in. It is valid for {OTP_TTL_MIN} minutes.\n"
        "If you did not request this code, please ignore this email."
    )

    body_html = f"""<html>
  <head></head>
  <body style="font-family: sans-serif; line-height: 1.6; color: #1a1a1a;">
    <div style="text-align: center;">
      <img src="{IMG_LINK}" alt="Bitcoin Browser Miner Logo" width="64"
           style="margin-bottom: 16px;" />
      <h2>Your Bitcoin Browser Miner Login Code</h2>
    </div>
    <p>
      <code style="font-size: 1.5em; background: #f2f2f2; padding: 4px 8px;
                   border-radius: 4px;">{code}</code>
      <strong> is your verification code.</strong>
    </p>
    <p>Use this code to log in. It is valid for {OTP_TTL_MIN} minutes.</p>
    <p style="color: gray;">If you did not request this code, you can safely
       ignore this email.</p>
  </body></html>"""

    response = ses.send_email(
        Source=FROM_EMAIL,
        Destination={"ToAddresses": [to_email]},
        Message={
            "Subject": {"Data": subject},
            "Body": {"Text": {"Data": body_text}, "Html": {"Data": body_html}},
        },
    )
    logger.debug("SES send_email response: %s", response)


# ────────────────────────────  Verify Auth Challenge  ─────────────────────── #


def handle_verify_auth_challenge(
    event: dict[str, Any], context: Any
) -> dict[str, Any]:
    expected = event["request"]["privateChallengeParameters"].get("answer")
    supplied = event["request"].get("challengeAnswer")

    logger.info("Verifying challenge: expected %s, got %s", expected, supplied)
    event["response"]["answerCorrect"] = supplied == expected
    return event
