# Website Module

## Manually Setting Up Amazon SES for OTP Emails

SES (or some other non-AWS emailing service) will need to be setup for your domain, and both dev and prod environments will use it. This is needed for fully password-less OTP sign-up and login with Cognito.

### 1. Open the SES Console

Go to the [AWS SES console](https://console.aws.amazon.com/ses/).

### 2. Verify Your Domain

1.  In the SES console navigation pane, go to **Verified identities**.
2.  Click the **Create identity** button.
3.  Select **Domain** as the identity type.
4.  Enter the domain you want to send emails from (e.g., `yourdomain.com`).
5.  Follow the instructions provided by SES to add the verification **TXT record** to your domain's DNS settings (e.g., via AWS Route 53 or your domain registrar).

### 3. Enable DKIM

DomainKeys Identified Mail (DKIM) adds a digital signature to your emails, improving deliverability.

1.  Once your domain identity is created in SES, select it from the **Verified identities** list.
2.  Go to the **Authentication** tab.
3.  Under the DKIM section, ensure it's enabled (Easy DKIM is recommended).
4.  Add the three **CNAME records** provided by SES to your domain's DNS settings.

### 4. Wait for Verification

*   Allow some time for the DNS changes (TXT and CNAME records) to propagate across the internet.
*   SES will update the status in the console. Your domain identity status should change to **Verified**, and the DKIM status should show as **Successful**.

### 5. Request Production Access

*   By default, new SES accounts operate in a **sandbox environment**. This means you can only send emails *to* email addresses that you have also verified within SES.
*   To send emails to *any* email address (which is necessary for OTPs), you need to request production access.
*   Follow the AWS documentation or links within the SES console to **request production access** (this usually involves explaining your use case and how you'll handle bounces/complaints). [Link to request production access (if available, otherwise instruct user to find it in console)].

### 6. Use a Verified "From" Address

*   When sending emails via SES, ensure the "From" address you use belongs to your verified domain (e.g., `noreply@yourdomain.com`, `support@yourdomain.com`). Sending from an unverified domain or address will result in errors.

# BTCNode Module

After deploying you'll need to transfer the following to the bitcoin node:
    *   `AWS_REGION`: Your AWS region (e.g., `us-west-2`).
    *   `AWS_IOT_THING_NAME`: The name of your IoT Thing (e.g., `piBtcNode01`).
    *   `AWS_IOT_CREDENTIALS_ENDPOINT`: Your AWS IoT Core Credentials Endpoint. You can find this in the AWS IoT Core console under "Settings" -> "Device data endpoints". It will be in the format `xxxxxxxxxxxxx-ats.iot.your-region.amazonaws.com`.
    *   `AWS_IOT_CERTIFICATE_ARN`: The ARN of your IoT certificate. You can get this from the output of your Terraform module or the AWS IoT Core console.
    *   `AWS_IOT_PRIVATE_KEY_PATH`: The absolute path to your private key file on the Pi (e.g., `/home/pi/.aws-iot-credentials/<your_certificate_id>-private.pem.key`).
    *   `AWS_IOT_CERTIFICATE_PATH`: The absolute path to your certificate file on the Pi (e.g., `/home/pi/.aws-iot-credentials/<your_certificate_id>-certificate.pem.crt`).
    *   `AWS_CA_BUNDLE`: The absolute path to the Amazon Root CA certificate file on the Pi (e.g., `/home/pi/.aws-iot-credentials/AmazonRootCA1.pem`).
    *   `AWS_ROLE_ARN`: The ARN of the IAM Role that your IoT policy allows you to assume via the Role Alias. This is the role with permissions to interact with other AWS services (S3, SQS, etc.).
    *   `AWS_ROLE_SESSION_NAME`: A name for the session (e.g., `pi-miner-session`).
    