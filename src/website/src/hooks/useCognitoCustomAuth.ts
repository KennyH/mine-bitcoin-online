'use client'

import { useState } from 'react';
import {
  CognitoIdentityProviderClient,
  SignUpCommand,
  InitiateAuthCommand,
  RespondToAuthChallengeCommand,
} from '@aws-sdk/client-cognito-identity-provider';

const REGION = process.env.NEXT_PUBLIC_AWS_REGION!;
const CLIENT_ID = process.env.NEXT_PUBLIC_COGNITO_CLIENT_ID!;

const client = new CognitoIdentityProviderClient({ region: REGION });

type Step = "form" | "otp" | "success";

export function useCognitoCustomAuth() {
  const [step, setStep] = useState<Step>("form");
  const [session, setSession] = useState<string | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [loading, setLoading] = useState(false);

  // 1. Sign up (for new users)
  const signUp = async (email: string, name: string, tosAccepted: boolean) => {
    setLoading(true);
    setError(null);
    try {
      const password = Math.random().toString(36) + "A1!"; // meets any policy
      const command = new SignUpCommand({
        ClientId: CLIENT_ID,
        Username: email,
        Password: password,
        UserAttributes: [
          { Name: "email", Value: email },
          { Name: "name", Value: name },
          { Name: "custom:tos_accepted", Value: tosAccepted ? "true" : "false" },
        ],
      });
      await client.send(command);
      return true;
    } catch (err: unknown) {
      // If user already exists, treat as success for sign-in flow
      if (isErrorWithName(err) && err.name === "UsernameExistsException") {
        return true;
      }
      if (isErrorWithMessage(err)) {
        setError(err.message);
      } else {
        setError("Sign up failed");
      }
      return false;
    }
  };

  // 2. Start custom auth (sign-in)
  const startAuth = async (email: string) => {
    setLoading(true);
    setError(null);
    try {
      const command = new InitiateAuthCommand({
        AuthFlow: "CUSTOM_AUTH",
        ClientId: CLIENT_ID,
        AuthParameters: {
          USERNAME: email,
        },
      });
      const result = await client.send(command);
      setSession(result.Session || null);
      setStep("otp");
      setError(null);
      return true;
    } catch (err: unknown) {
      if (isErrorWithMessage(err)) {
        setError(err.message);
      } else {
        setError("Failed to start authentication");
      }
      return false;
    } finally {
      setLoading(false);
    }
  };

  // 3. Respond to OTP challenge
  const submitOtp = async (email: string, otp: string) => {
    setLoading(true);
    setError(null);
    try {
      const command = new RespondToAuthChallengeCommand({
        ClientId: CLIENT_ID,
        ChallengeName: "CUSTOM_CHALLENGE",
        Session: session!,
        ChallengeResponses: {
          USERNAME: email,
          ANSWER: otp,
        },
      });
      const result = await client.send(command);
      if (result.AuthenticationResult) {
        setStep("success");
        setError(null);
        return result.AuthenticationResult;
      } else if (result.ChallengeName === "CUSTOM_CHALLENGE") {
        setError("Incorrect code. Try again.");
        return false;
      } else {
        setError("Unexpected challenge state.");
        return false;
      }
    } catch (err: unknown) {
      if (isErrorWithMessage(err)) {
        setError(err.message || "Verification failed");
      } else {
        setError("Failed to start authentication");
      }
      return false;
    } finally {
      setLoading(false);
    }
  };

  const reset = () => {
    setStep("form");
    setSession(null);
    setError(null);
    setLoading(false);
  };

  return {
    step,
    error,
    loading,
    signUp,
    startAuth,
    submitOtp,
    reset,
  };
}

function isErrorWithName(e: unknown): e is { name: string } {
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  return typeof e === "object" && e !== null && "name" in e && typeof (e as any).name === "string";
}

function isErrorWithMessage(e: unknown): e is { message: string } {
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  return typeof e === "object" && e !== null && "message" in e && typeof (e as any).message === "string";
}
