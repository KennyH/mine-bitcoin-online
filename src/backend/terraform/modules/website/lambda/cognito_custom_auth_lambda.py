import secrets
import boto3
import os

ses = boto3.client("ses", region_name="us-west-2")
FROM_EMAIL = "noreply@bitcoinbrowserminer.com"

def lambda_handler(event, context):
    print("Lambda triggered. Event:", event)
    trigger_source = event.get("triggerSource")
    print(f"Trigger source: {trigger_source}")
    trigger_handlers = {
        "PreSignUp_SignUp": handle_pre_sign_up,
        "DefineAuthChallenge_Authentication": handle_define_auth_challenge,
        "CreateAuthChallenge_Authentication": handle_create_auth_challenge,
        "VerifyAuthChallengeResponse_Authentication": handle_verify_auth_challenge
    }

    handler_function = trigger_handlers.get(trigger_source)
    if not handler_function:
        print("No handler for trigger source:", trigger_source)
        return event

    return handler_function(event, context)

def handle_pre_sign_up(event, context):
    print("PreSignUp: Auto-confirming and auto-verifying user.")
    event["response"]["autoConfirmUser"] = True
    event["response"]["autoVerifyEmail"] = True
    return event

def handle_define_auth_challenge(event, context):
    print("DefineAuthChallenge: Session:", event["request"]["session"])
    session = event["request"]["session"]

    if len(session) == 0:
        print("No session, issuing CUSTOM_CHALLENGE.")
        event["response"]["challengeName"] = "CUSTOM_CHALLENGE"
        event["response"]["issueTokens"] = False
        event["response"]["failAuthentication"] = False
    else:
        if session[-1]["challengeName"] == "CUSTOM_CHALLENGE" and session[-1]["challengeResult"]:
            print("Previous challenge succeeded, issuing tokens.")
            event["response"]["issueTokens"] = True
            event["response"]["failAuthentication"] = False
        else:
            print("Previous challenge failed or not present, issuing another CUSTOM_CHALLENGE.")
            event["response"]["challengeName"] = "CUSTOM_CHALLENGE"
            event["response"]["issueTokens"] = False
            event["response"]["failAuthentication"] = False

    return event

def handle_create_auth_challenge(event, context):
    print("CreateAuthChallenge: Event:", event)
    if event["request"]["challengeName"] == "CUSTOM_CHALLENGE":
        challenge_code = str(secrets.randbelow(10**6)).zfill(6)
        user_attributes = event["request"].get("userAttributes", {})
        email = user_attributes.get("email")
        print(f"Generated OTP code: {challenge_code} for email: {email}")

        event["response"]["publicChallengeParameters"] = {
            "email": email
        }
        event["response"]["privateChallengeParameters"] = {
            "answer": challenge_code
        }

        if email:
            try:
                print(f"Attempting to send OTP code {challenge_code} to {email}")
                send_otp_email(challenge_code, email)
                print("Email sent successfully.")
            except Exception as e:
                print(f"Error sending email: {e}")
        else:
            print("No email found in userAttributes; cannot send OTP.")
    return event

def send_otp_email(code, to_email):
    subject = "Your Bitcoin Browser Miner Login Code"
    body = f"Your verification code is: {code}\n\nUse this code to log in.\nIf you did not request this code, please ignore this email."
    response = ses.send_email(
        Source=FROM_EMAIL,
        Destination={"ToAddresses": [to_email]},
        Message={
            "Subject": {"Data": subject},
            "Body": {"Text": {"Data": body}},
        },
    )
    print("SES send_email response:", response)

def handle_verify_auth_challenge(event, context):
    expected_answer = event["request"]["privateChallengeParameters"].get("answer")
    user_answer = event["request"]["challengeAnswer"]
    print(f"Verifying challenge: expected {expected_answer}, got {user_answer}")
    event["response"]["answerCorrect"] = user_answer == expected_answer
    return event
