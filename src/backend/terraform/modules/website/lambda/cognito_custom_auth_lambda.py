import secrets
import boto3
import logging
import os

LOG_LEVEL = os.environ.get("LOG_LEVEL", "INFO").upper()
logger = logging.getLogger()
logger.setLevel(getattr(logging, LOG_LEVEL, logging.INFO))

ses = boto3.client("ses", region_name="us-west-2")
FROM_EMAIL = "noreply@bitcoinbrowserminer.com"

def lambda_handler(event, context):
    logger.info("Lambda triggered. Event: %s", event)
    trigger_source = event.get("triggerSource")
    logger.info("Trigger source: %s", trigger_source)
    trigger_handlers = {
        "PreSignUp_SignUp": handle_pre_sign_up,
        "DefineAuthChallenge_Authentication": handle_define_auth_challenge,
        "CreateAuthChallenge_Authentication": handle_create_auth_challenge,
        "VerifyAuthChallengeResponse_Authentication": handle_verify_auth_challenge
    }

    handler_function = trigger_handlers.get(trigger_source)
    if not handler_function:
        logger.warning("No handler for trigger source: %s", trigger_source)
        return event

    return handler_function(event, context)

def handle_pre_sign_up(event, context):
    logger.info("PreSignUp: Auto-confirming and auto-verifying user.")
    event["response"]["autoConfirmUser"] = True
    event["response"]["autoVerifyEmail"] = True
    return event

def handle_define_auth_challenge(event, context):
    session = event["request"]["session"]
    logger.info("DefineAuthChallenge: Session: %s", session)

    if len(session) == 0:
        logger.info("No session, issuing CUSTOM_CHALLENGE.")
        event["response"]["challengeName"] = "CUSTOM_CHALLENGE"
        event["response"]["issueTokens"] = False
        event["response"]["failAuthentication"] = False
    else:
        last = session[-1]
        if last["challengeName"] == "CUSTOM_CHALLENGE" and last["challengeResult"]:
            logger.info("Previous challenge succeeded, issuing tokens.")
            event["response"]["issueTokens"] = True
            event["response"]["failAuthentication"] = False
        else:
            logger.info("Previous challenge failed or not present, issuing another CUSTOM_CHALLENGE.")
            event["response"]["challengeName"] = "CUSTOM_CHALLENGE"
            event["response"]["issueTokens"] = False
            event["response"]["failAuthentication"] = False

    return event

def handle_create_auth_challenge(event, context):
    logger.info("CreateAuthChallenge triggered.")
    if event["request"]["challengeName"] == "CUSTOM_CHALLENGE":
        challenge_code = str(secrets.randbelow(10**6)).zfill(6)
        user_attributes = event["request"].get("userAttributes", {})
        email = user_attributes.get("email")
        logger.info("Generated OTP code %s for email %s", challenge_code, email)

        event["response"]["publicChallengeParameters"] = {
            "email": email
        }
        event["response"]["privateChallengeParameters"] = {
            "answer": challenge_code
        }

        if email:
            try:
                logger.info("Attempting to send OTP code to %s", email)
                send_otp_email(challenge_code, email)
                logger.info("Email sent successfully.")
            except Exception as e:
                logger.error("Error sending email: %s", e)
        else:
            logger.warning("No email found in userAttributes; cannot send OTP.")
    return event

#TODO: Make a static assets location like https://assets.bitcoinbrowserminer.com/logo.png
def send_otp_email(code, to_email):
    subject = "Your Bitcoin Browser Miner Login Code"
    body_text = f"Your verification code is: {code}\n\nUse this code to log in.\nIf you did not request this code, please ignore this email."
    body_html = f"""<html>
  <head></head>
  <body style="font-family: sans-serif; line-height: 1.6; color: #1a1a1a;">
    <div style="text-align: center;">
      <img src="https://dev-env.bitcoinbrowserminer.com/images/bitcoin.png" alt="Bitcoin Browser Miner Logo" width="64" style="margin-bottom: 16px;" />
      <h2>Your Bitcoin Browser Miner Login Code</h2>
    </div>
    <p><strong>Your verification code is:</strong> 
       <code style="font-size: 1.5em; background: #f2f2f2; padding: 4px 8px; border-radius: 4px;">{code}</code></p>
    <p>Use this code to log in.</p>
    <p style="color: gray;">If you did not request this code, you can safely ignore this email.</p>
  </body>
</html>"""
    
    response = ses.send_email(
        Source=FROM_EMAIL,
        Destination={"ToAddresses": [to_email]},
        Message={
            "Subject": {"Data": subject},
            "Body": {
                "Text": {"Data": body_text}, # Plaintext fallback
                "Html": {"Data": body_html},
            },
        },
    )
    logger.debug("SES send_email response: %s", response)

def handle_verify_auth_challenge(event, context):
    expected_answer = event["request"]["privateChallengeParameters"].get("answer")
    user_answer = event["request"]["challengeAnswer"]
    logger.info("Verifying challenge: expected %s, got %s", expected_answer, user_answer)
    event["response"]["answerCorrect"] = user_answer == expected_answer
    return event
