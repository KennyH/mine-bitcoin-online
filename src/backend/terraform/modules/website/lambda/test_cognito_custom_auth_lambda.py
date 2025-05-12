import pytest
from unittest.mock import patch, MagicMock
import cognito_custom_auth_lambda

# ────────────────────────────  Mock Event Structures  ──────────────────────────── #

mock_pre_sign_up_event_success = {
    "triggerSource": "PreSignUp_SignUp",
    "request": {
        "userAttributes": {
            "custom:tos_accepted": "true",
            "email": "test@example.com" # Include email for consistency
        }
    },
    "response": {}
}

mock_pre_sign_up_event_no_tos = {
    "triggerSource": "PreSignUp_SignUp",
    "request": {
        "userAttributes": {
            "email": "test@example.com" # Include email
        }
    },
    "response": {}
}

mock_define_auth_challenge_empty_session = {
    "triggerSource": "DefineAuthChallenge_Authentication",
    "request": {
        "userAttributes": { # Include userAttributes for potential use
             "email": "test@example.com"
        },
        "session": []
    },
    "response": {}
}

mock_define_auth_challenge_previous_success = {
    "triggerSource": "DefineAuthChallenge_Authentication",
    "request": {
        "userAttributes": {
             "email": "test@example.com"
        },
        "session": [
            {"challengeName": "CUSTOM_CHALLENGE", "challengeResult": True, "challengeMetadata": "some_metadata"}
        ]
    },
    "response": {}
}

mock_define_auth_challenge_previous_failure = {
    "triggerSource": "DefineAuthChallenge_Authentication",
    "request": {
        "userAttributes": {
             "email": "test@example.com"
        },
        "session": [
            {"challengeName": "CUSTOM_CHALLENGE", "challengeResult": False, "challengeMetadata": "some_metadata"}
        ]
    },
    "response": {}
}

mock_create_auth_challenge_event_custom = {
    "triggerSource": "CreateAuthChallenge_Authentication",
    "request": {
        "challengeName": "CUSTOM_CHALLENGE",
        "userAttributes": {
            "email": "test@example.com"
        }
    },
    "response": {}
}

mock_create_auth_challenge_event_other = {
    "triggerSource": "CreateAuthChallenge_Authentication",
    "request": {
        "challengeName": "SMS_MFA", # Another challenge type
        "userAttributes": {
            "email": "test@example.com"
        }
    },
    "response": {}
}

mock_create_auth_challenge_event_no_email = {
    "triggerSource": "CreateAuthChallenge_Authentication",
    "request": {
        "challengeName": "CUSTOM_CHALLENGE",
        "userAttributes": {} # Missing email
    },
    "response": {}
}


mock_verify_auth_challenge_event_correct = {
    "triggerSource": "VerifyAuthChallengeResponse_Authentication",
    "request": {
        "privateChallengeParameters": {
            "answer": "123456"
        },
        "challengeAnswer": "123456"
    },
    "response": {}
}

mock_verify_auth_challenge_event_incorrect = {
    "triggerSource": "VerifyAuthChallengeResponse_Authentication",
    "request": {
        "privateChallengeParameters": {
            "answer": "123456"
        },
        "challengeAnswer": "654321"
    },
    "response": {}
}

mock_unhandled_trigger_event = {
    "triggerSource": "PostConfirmation_ConfirmSignUp", # Unhandled trigger
    "request": {},
    "response": {}
}


# ────────────────────────────  Fixtures  ──────────────────────────── #

@pytest.fixture
def mock_ses_client(mocker):
    """Fixture to mock the SES client."""
    mock_client = MagicMock()
    mocker.patch.object(cognito_custom_auth_lambda, 'ses', mock_client)
    return mock_client


@pytest.fixture(autouse=True)
def cognito_lambda_module(mocker):
    """Fixture to set necessary environment variables and import the module."""
    mocker.patch.dict('os.environ', {
        'LOG_LEVEL': 'INFO',
        'AWS_REGION': 'us-west-2',
        'FROM_EMAIL': 'noreply@bitcoinbrowserminer.com',
        'IMG_LINK': 'https://example.com/image.png',
        'OTP_TTL_MIN': '3'
    })
    # Import the module after setting environment variables
    import cognito_custom_auth_lambda as ccal  # alias to avoid naming conflicts
    yield ccal


@pytest.fixture
def mock_one_time_code(mocker):
    """Fixture to mock the _one_time_code function."""
    mock_func = mocker.patch.object(
        cognito_custom_auth_lambda, '_one_time_code', return_value="987654"
    )
    return mock_func


# ────────────────────────────  Test Cases  ──────────────────────────── #

def test_lambda_handler_dispatches_to_correct_handler():
    # This test checks that the lambda_handler calls the right function
    with patch.object(cognito_custom_auth_lambda, 'handle_pre_sign_up') as mock_pre_sign_up:
        cognito_custom_auth_lambda.lambda_handler(mock_pre_sign_up_event_success, None)
        mock_pre_sign_up.assert_called_once_with(mock_pre_sign_up_event_success, None)

    with patch.object(cognito_custom_auth_lambda, 'handle_define_auth_challenge') as mock_define_challenge:
        cognito_custom_auth_lambda.lambda_handler(mock_define_auth_challenge_empty_session, None)
        mock_define_challenge.assert_called_once_with(mock_define_auth_challenge_empty_session, None)

    with patch.object(cognito_custom_auth_lambda, 'handle_create_auth_challenge') as mock_create_challenge:
        cognito_custom_auth_lambda.lambda_handler(mock_create_auth_challenge_event_custom, None)
        mock_create_challenge.assert_called_once_with(mock_create_auth_challenge_event_custom, None)

    with patch.object(cognito_custom_auth_lambda, 'handle_verify_auth_challenge') as mock_verify_challenge:
        cognito_custom_auth_lambda.lambda_handler(mock_verify_auth_challenge_event_correct, None)
        mock_verify_challenge.assert_called_once_with(mock_verify_auth_challenge_event_correct, None)


def test_lambda_handler_returns_event_for_unhandled_trigger():
    event = cognito_custom_auth_lambda.lambda_handler(mock_unhandled_trigger_event, None)
    assert event == mock_unhandled_trigger_event # Should return the original event

# ────────────────────────────  Pre-Sign-Up Tests  ──────────────────────────── #

def test_handle_pre_sign_up_success():
    event = cognito_custom_auth_lambda.handle_pre_sign_up(mock_pre_sign_up_event_success, None)
    assert event["response"]["autoConfirmUser"] is True
    assert event["response"]["autoVerifyEmail"] is True

def test_handle_pre_sign_up_no_tos_raises_exception():
    with pytest.raises(Exception, match="You must accept the Terms of Service to sign up."):
        cognito_custom_auth_lambda.handle_pre_sign_up(mock_pre_sign_up_event_no_tos, None)

def test_handle_pre_sign_up_missing_attributes_raises_exception():
    event = {
        "triggerSource": "PreSignUp_SignUp",
        "request": {}, # Missing request or userAttributes
        "response": {}
    }
    with pytest.raises(Exception, match="You must accept the Terms of Service to sign up."):
        cognito_custom_auth_lambda.handle_pre_sign_up(event, None)


# ────────────────────────────  Define Auth Challenge Tests  ──────────────────────────── #

def test_handle_define_auth_challenge_empty_session():
    event = cognito_custom_auth_lambda.handle_define_auth_challenge(mock_define_auth_challenge_empty_session, None)
    assert event["response"]["challengeName"] == "CUSTOM_CHALLENGE"
    assert event["response"]["issueTokens"] is False
    assert event["response"]["failAuthentication"] is False

def test_handle_define_auth_challenge_previous_success():
    event = cognito_custom_auth_lambda.handle_define_auth_challenge(mock_define_auth_challenge_previous_success, None)
    assert event["response"]["issueTokens"] is True
    assert event["response"]["failAuthentication"] is False

def test_handle_define_auth_challenge_previous_failure():
    event = cognito_custom_auth_lambda.handle_define_auth_challenge(mock_define_auth_challenge_previous_failure, None)
    assert event["response"]["challengeName"] == "CUSTOM_CHALLENGE"
    assert event["response"]["issueTokens"] is False
    assert event["response"]["failAuthentication"] is False

def test_handle_define_auth_challenge_other_challenge_in_session():
    event = {
        "triggerSource": "DefineAuthChallenge_Authentication",
        "request": {
            "userAttributes": {
                 "email": "test@example.com"
            },
            "session": [
                {"challengeName": "SMS_MFA", "challengeResult": True, "challengeMetadata": "some_metadata"}
            ]
        },
        "response": {}
    }
    result_event = cognito_custom_auth_lambda.handle_define_auth_challenge(event, None)
    # Should still issue a CUSTOM_CHALLENGE if the last wasn't a successful custom one
    assert result_event["response"]["challengeName"] == "CUSTOM_CHALLENGE"


# ────────────────────────────  Create Auth Challenge Tests  ──────────────────────────── #

@pytest.fixture
def mock_one_time_code(mocker):
    """Fixture to mock the _one_time_code function."""
    mock_func = mocker.patch.object(
        cognito_custom_auth_lambda, '_one_time_code', return_value="987654"
    )
    return mock_func


def test_handle_create_auth_challenge_sends_email_for_custom_challenge(cognito_lambda_module, mock_ses_client, mock_one_time_code):
    ccal = cognito_lambda_module

    event = ccal.handle_create_auth_challenge(mock_create_auth_challenge_event_custom, None)
    assert len(str(event)) > 0

    # Assert that ses.send_email was called with the correct parameters
    mock_ses_client.send_email.assert_called_once()
    call_args = mock_ses_client.send_email.call_args[1]

    assert call_args['Source'] == 'noreply@bitcoinbrowserminer.com'
    assert call_args['Destination'] == {'ToAddresses': ['test@example.com']}
    assert "Your Bitcoin Browser Miner Login Code" in call_args['Message']['Subject']['Data']
    assert "987654 is your Bitcoin Browser Miner code." in call_args['Message']['Body']['Text']['Data']


def test_handle_create_auth_challenge_does_not_send_email_for_other_challenge(mock_ses_client):
    cognito_custom_auth_lambda.handle_create_auth_challenge(mock_create_auth_challenge_event_other, None)
    mock_ses_client.send_email.assert_not_called()


def test_handle_create_auth_challenge_no_email_returns_error_params(mock_ses_client):
    event = cognito_custom_auth_lambda.handle_create_auth_challenge(mock_create_auth_challenge_event_no_email, None)

    mock_ses_client.send_email.assert_not_called()
    assert event["response"]["publicChallengeParameters"] == {"error": "NO_EMAIL"}
    assert event["response"]["privateChallengeParameters"] == {}
    assert event["response"]["challengeMetadata"] == "NO_EMAIL"

@patch.object(cognito_custom_auth_lambda.ses, 'send_email')
def test_send_otp_email_calls_ses_send_email(mock_send_email):
    code = "112233"
    to_email = "recipient@example.com"
    cognito_custom_auth_lambda.send_otp_email(code, to_email)

    mock_send_email.assert_called_once()
    call_args = mock_send_email.call_args[1]

    assert call_args['Destination'] == {'ToAddresses': ['recipient@example.com']}
    assert "112233 is your Bitcoin Browser Miner code." in call_args['Message']['Body']['Text']['Data']
    html_body = call_args['Message']['Body']['Html']['Data']
    assert code in html_body


# ────────────────────────────  Verify Auth Challenge Tests  ──────────────────────────── #

def test_handle_verify_auth_challenge_correct():
    event = cognito_custom_auth_lambda.handle_verify_auth_challenge(mock_verify_auth_challenge_event_correct, None)
    assert event["response"]["answerCorrect"] is True

def test_handle_verify_auth_challenge_incorrect():
    event = cognito_custom_auth_lambda.handle_verify_auth_challenge(mock_verify_auth_challenge_event_incorrect, None)
    assert event["response"]["answerCorrect"] is False

