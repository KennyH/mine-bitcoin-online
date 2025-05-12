import pytest
import json

# Basic event structure for API Gateway proxy integration
mock_api_gateway_event = {
    "body": '{"token": "mock_token"}',
    "resource": "/{proxy+}",
    "requestContext": {
        "resourceId": "123456",
        "apiId": "abcdefghij",
        "httpMethod": "POST",
        "path": "/verify",
        "identity": {
            "sourceIp": "192.168.1.1"
        },
        "protocol": "HTTP/1.1",
        "stage": "prod"
    },
    "queryStringParameters": None,
    "headers": {
        "Accept": "application/json",
        "Content-Type": "application/json"
    },
    "pathParameters": {"proxy": "verify"},
    "httpMethod": "POST",
    "stageVariables": None,
    "isBase64Encoded": False
}

# Basic event structure for a malformed body
mock_malformed_event = {
    "body": 'invalid json',
    "requestContext": {
        "http": {
            "sourceIp": "192.168.1.1"
        }
    }
}

# Basic event structure with missing token
mock_missing_token_event = {
    "body": '{}',
    "requestContext": {
        "http": {
            "sourceIp": "192.168.1.1"
        }
    }
}


@pytest.fixture(autouse=True)
def set_turnstile_secret_key(mocker):
    """Fixture to set the TURNSTILE_SECRET_KEY environment variable for tests."""
    mocker.patch.dict('os.environ', {'TURNSTILE_SECRET_KEY': 'dummy_secret'})

    import cf_turnstile_lambda
    yield cf_turnstile_lambda


def test_lambda_handler_success(set_turnstile_secret_key, mocker):
    cf_turnstile_lambda = set_turnstile_secret_key

    # Mock the _verify_with_turnstile function to return a successful response
    mocker.patch.object(
        cf_turnstile_lambda,
        "_verify_with_turnstile",
        return_value={"success": True}
    )

    response = cf_turnstile_lambda.lambda_handler(mock_api_gateway_event, None)

    assert response["statusCode"] == 200
    body = json.loads(response["body"])
    assert body["success"] is True
    assert body["message"] == "Token verified"


def test_lambda_handler_missing_token(set_turnstile_secret_key):
    cf_turnstile_lambda = set_turnstile_secret_key
    response = cf_turnstile_lambda.lambda_handler(mock_missing_token_event, None)

    assert response["statusCode"] == 400
    body = json.loads(response["body"])
    assert body["message"] == "Token is required"


def test_lambda_handler_malformed_json(set_turnstile_secret_key):
    cf_turnstile_lambda = set_turnstile_secret_key
    response = cf_turnstile_lambda.lambda_handler(mock_malformed_event, None)

    assert response["statusCode"] == 400
    body = json.loads(response["body"])
    assert body["message"] == "Invalid JSON body"

