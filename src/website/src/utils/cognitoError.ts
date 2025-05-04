/**
 * @fileoverview Utility functions and types for handling AWS Cognito errors.
 *
 * Exports:
 * - `CognitoError`: A type extending AWS SDK's `ServiceException` to potentially
 *   include challenge-specific error details.
 * - `isCognitoError`: A type guard function to safely check if an unknown error
 *   object is likely a Cognito service error.
 */
import { ServiceException } from '@smithy/smithy-client';

interface ChallengeErrorData {
  challengeParameters?: { error?: string };
}

export type CognitoError = ServiceException & {
  $response?: { data?: ChallengeErrorData };
};

export function isCognitoError(e: unknown): e is CognitoError {
  return (
    typeof e === "object" &&
    e !== null &&
    "name" in e &&
    "message" in e
  );
}
