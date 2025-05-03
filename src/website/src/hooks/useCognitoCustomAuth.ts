'use client'

import { useState } from 'react';
import {
  CognitoIdentityProviderClient,
  SignUpCommand,
  InitiateAuthCommand,
  RespondToAuthChallengeCommand,
} from '@aws-sdk/client-cognito-identity-provider';
import { isCognitoError } from "@/utils/cognitoError";

const REGION = process.env.NEXT_PUBLIC_AWS_REGION!;
const CLIENT_ID = process.env.NEXT_PUBLIC_COGNITO_CLIENT_ID!;

const client = new CognitoIdentityProviderClient({ region: REGION });

type Step = "form" | "otp" | "success";
type AuthErrorCode =
  | "None"
  | "UserNotFound"
  | "OtpIncorrect"
  | "Aws"
  | "Unknown";

export function useCognitoCustomAuth() {
  const [step, setStep] = useState<Step>("form");
  const [session, setSession] = useState<string | null>(null);
  const [errorMessage, setErrorMessage] = useState<string | null>(null);
  const [errorCode, setErrorCode] = useState<AuthErrorCode>("None");
  const [loading, setLoading] = useState(false);

  // 1. Sign up (for new users)
  const signUp = async (email: string, name: string, tosAccepted: boolean) => {
    setLoading(true);
    setErrorMessage(null);
    setErrorCode("None");
  
    try {
      const password = Math.random().toString(36) + "A1!";
      await client.send(
        new SignUpCommand({
          ClientId: CLIENT_ID,
          Username: email,
          Password: password,
          UserAttributes: [
            { Name: "email", Value: email },
            { Name: "name", Value: name },
            { Name: "custom:tos_accepted", Value: tosAccepted ? "true" : "false" },
          ],
        })
      );
      localStorage.setItem("created_user", "true");
      return true;
    } catch (err: unknown) {
      // user already exists. Do sign-in path
      if (isCognitoError(err) && err.name === "UsernameExistsException") {
        return true;
      }
  
      // any other Cognito service error
      if (isCognitoError(err)) {
        setErrorCode("Aws");
        setErrorMessage(err.message);
      } else {
        // unknown or network error
        setErrorCode("Unknown");
        setErrorMessage("Sign-up failed");
      }
      return false;
    } finally {
      setLoading(false);
    }
  };
  
  // 2. Start custom auth (sign-in)
  const startAuth = async (email: string) => {
    setLoading(true);
    setErrorMessage(null);
    setErrorCode("None");
    try {
      const result = await client.send(
        new InitiateAuthCommand({
          AuthFlow: "CUSTOM_AUTH",
          ClientId: CLIENT_ID,
          AuthParameters: { USERNAME: email },
        })
      );
      const errFlag = result.ChallengeParameters?.error as
        | "NO_EMAIL"
        | undefined;

      if (errFlag === "NO_EMAIL") {
        // unknown user...
        setErrorCode("UserNotFound");
        setErrorMessage(
          "No account matching that email."
        );
        return false;
      }

      // normal path
      setSession(result.Session ?? null);
      setStep("otp");
      return true;
    } catch (err: unknown) {
      if (isCognitoError(err)) {
        console.log(err);
        const userNotFound =
          err.name === "NotAuthorizedException" &&
          err.$response?.data?.challengeParameters?.error === "NO_EMAIL";
    
        if (userNotFound) {
          setErrorCode("UserNotFound");
          setErrorMessage(
            "We couldn't find an account for that email."
          );
        } else {
          setErrorCode("Aws");
          setErrorMessage(err.message);
        }
      } else {
        setErrorCode("Unknown");
        setErrorMessage("Failed to authenticate");
      }
      return false;
    } finally {
      setLoading(false);
    }
  };

  // 3. Respond to OTP challenge
  const submitOtp = async (email: string, otp: string) => {
    setLoading(true);
    setErrorMessage(null);
    setErrorCode("None");
  
    try {
      const result = await client.send(
        new RespondToAuthChallengeCommand({
          ClientId: CLIENT_ID,
          ChallengeName: "CUSTOM_CHALLENGE",
          Session: session!,
          ChallengeResponses: {
            USERNAME: email,
            ANSWER: otp,
          },
        })
      );
  
      if (result.AuthenticationResult) {
        setStep("success");
        setErrorMessage(null);
        setErrorCode("None");
        return result.AuthenticationResult;
      }
  
      if (result.ChallengeName === "CUSTOM_CHALLENGE") {
        setErrorCode("OtpIncorrect");
        setErrorMessage("Incorrect code. Try again.");
        return false;
      }
  
      setErrorCode("Aws");
      setErrorMessage("Unexpected challenge state.");
      return false;
    } catch (err: unknown) {
      if (isCognitoError(err)) {
        // OTP-related service errors
        const otpFail =
          err.name === "CodeMismatchException" ||
          err.name === "ExpiredCodeException" ||
          err.name === "NotAuthorizedException"; // sometimes returned by PUE masking
  
        if (otpFail) {
          setErrorCode("OtpIncorrect");
          setErrorMessage("Incorrect or expired code. Try again.");
        } else {
          setErrorCode("Aws");
          setErrorMessage(err.message);
        }
      } else {
        setErrorCode("Unknown");
        setErrorMessage("Verification failed");
      }
      return false;
    } finally {
      setLoading(false);
    }
  };

  const reset = () => {
    setStep("form");
    setSession(null);
    setErrorMessage(null);
    setErrorCode("None");
    setLoading(false);
  };

  return {
    step,
    loading,
    errorMessage,
    errorCode,
    signUp,
    startAuth,
    submitOtp,
    reset,
  };
}
