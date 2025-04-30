#import json
import secrets
import boto3
import os

ses = boto3.client("ses", region_name="us-west-2")
FROM_EMAIL = "noreply@bitcoinbrowserminer.com"

def lambda_handler(event, context):
    trigger_source = event.get("triggerSource")
    trigger_handlers = {
        "PreSignUp_SignUp": handle_pre_sign_up,
        "DefineAuthChallenge_Authentication": handle_define_auth_challenge,
        "CreateAuthChallenge_Authentication": handle_create_auth_challenge,
        "VerifyAuthChallengeResponse_Authentication": handle_verify_auth_challenge
    }

    handler_function = trigger_handlers.get(trigger_source)
    if not handler_function:
        return event

    return handler_function(event, context)

def handle_pre_sign_up(event, context):
    # Auto-confirm user to not require a password flow
    event["response"]["autoConfirmUser"] = True
    # auto-verify? maybe..
    event["response"]["autoVerifyEmail"] = True

    return event


def handle_define_auth_challenge(event, context):
    """
    If there's no existing session, that means this is a new auth request -> create a challenge.
    If the prior challenge was successful, we succeed. If the prior challenge failed, add a new challenge, etc.
    """
    # If there's an active session and the last challenge was successful, then auth is complete.
    # Cognito includes an array of "session" objects in event['request']['session']
    # Each item indicates the challenge result, e.g. SUCCESS or FAILURE
    session = event["request"]["session"]

    if len(session) == 0:
        # No existing session, present the custom challenge
        event["response"]["challengeName"] = "CUSTOM_CHALLENGE"
        event["response"]["issueTokens"] = False
        event["response"]["failAuthentication"] = False

    else:
        # If the user answered the last challenge correctly, issue tokens
        if session[-1]["challengeName"] == "CUSTOM_CHALLENGE" and session[-1]["challengeResult"]:
            event["response"]["issueTokens"] = True
            event["response"]["failAuthentication"] = False
        else:
            # The user’s code was incorrect. Can either fail or give them another chance
            event["response"]["challengeName"] = "CUSTOM_CHALLENGE"
            event["response"]["issueTokens"] = False
            event["response"]["failAuthentication"] = False

    return event


def handle_create_auth_challenge(event, context):
    """
    Creates the code for the custom challenge and store it in privateChallengeParameters.
    privateChallengeParameters are never exposed directly to the client, 
    but used by the VerifyAuthChallengeResponse step to check correctness.
    """
    # Only generate a new code if starting a new CUSTOM_CHALLENGE (i.e. no existing session or it failed)
    if event["request"]["challengeName"] == "CUSTOM_CHALLENGE":
        # Generate a 6-digit random code (using secrets for secure RNG)
        challenge_code = str(secrets.randbelow(10**6)).zfill(6)  # e.g. "045123"

        event["response"]["publicChallengeParameters"] = {
            "email": event["request"]["userAttributes"]["email"]
        }

        event["response"]["privateChallengeParameters"] = {
            "answer": challenge_code
        }

        print(f"Sending OTP code {challenge_code} to {event['request']['userAttributes']['email']}")
        send_otp_email(challenge_code, event['request']['userAttributes']['email'])
    return event


def send_otp_email(to_email, code):
    subject = "Your Bitcoin Browser Miner Login Code"
    body = f"Your verification code is: {code}\n\nUse this code to log in.\nIf you did not request this code, please ignore this email."
    ses.send_email(
        Source=FROM_EMAIL,
        Destination={"ToAddresses": [to_email]},
        Message={
            "Subject": {"Data": subject},
            "Body": {"Text": {"Data": body}},
        },
    )


def handle_verify_auth_challenge(event, context):
    """
    Compare the user-submitted code to the correct code from privateChallengeParameters.
    """
    expected_answer = event["request"]["privateChallengeParameters"].get("answer")
    user_answer = event["request"]["challengeAnswer"]
    event["response"]["answerCorrect"] = user_answer == expected_answer

    return event
