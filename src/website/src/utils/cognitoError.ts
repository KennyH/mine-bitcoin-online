import { ServiceException } from "@smithy/smithy-client";

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
