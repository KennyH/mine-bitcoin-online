"use client";

import React, { useState, useCallback } from 'react';
import Turnstile from 'turnstile-next';
import Modal from './Modal';
import { useCognitoCustomAuth } from '@/hooks/useCognitoCustomAuth';
import { useCognitoUser } from '@/context/CognitoUserContext';

type Tab = "signIn" | "signUp";

const turnstileSiteKey = process.env.NEXT_PUBLIC_TURNSTILE_SITE_KEY;
const turnstileVerificationEndpoint =
  process.env.NEXT_PUBLIC_TURNSTILE_VERIFICATION_ENDPOINT;

// TODO
// // When user successfully signs up:
// localStorage.setItem("created_user", "true");

// // When opening the modal:
// const createdUser = localStorage.getItem("created_user") === "true";
// <SignUpModal open={open} onClose={onClose} created_user={createdUser} />

export default function SignUpModal({
  open,
  onClose,
  created_user = false, // controls default tab
}: {
  open: boolean;
  onClose: () => void;
  created_user?: boolean;
}) {
  const [tab, setTab] = useState<Tab>(created_user ? "signIn" : "signUp");
  const [name, setName] = useState("");
  const [email, setEmail] = useState("");
  const [tosAccepted, setTosAccepted] = useState(false);
  const [otp, setOtp] = useState("");
  const [turnstileToken, setTurnstileToken] = useState<string | null>(null);
  const [turnstileError, setTurnstileError] = useState<string | null>(null);
  const [isVerifyingTurnstile, setIsVerifyingTurnstile] = useState(false);
  
  const {
    step,
    error: cognitoError,
    loading: cognitoLoading,
    signUp,
    startAuth,
    submitOtp,
    reset: resetCognito,
  } = useCognitoCustomAuth();
  const { login } = useCognitoUser();

  // --- Verify Turnstile Token
  const verifyTurnstile = async (token: string | null): Promise<boolean> => {
    if (!token) {
      setTurnstileError("Please complete the security check.");
      return false;
    }
    if (!turnstileVerificationEndpoint) {
      setTurnstileError("System error.");
      return false;
    }

    setTurnstileError(null);
    setIsVerifyingTurnstile(true);
    try {
      const response = await fetch(turnstileVerificationEndpoint, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ token }),
      });

      if (!response.ok) {
        const errorData = await response.json().catch(() => ({}));
        console.error("Turnstile verification failed:", response.status, errorData);
        setTurnstileError(
          `Security check failed (${response.status}). Please try again.`
        );
        return false;
      }

      const result = await response.json();
      if (result.success) {
        return true;
      } else {
        console.warn("Turnstile verification unsuccessful:", result["error-codes"]);
        setTurnstileError("Security check verification failed. Please try again.");
        return false;
      }
    } catch (error) {
      console.error("Error during Turnstile verification request:", error);
      setTurnstileError("An error occurred during the security check. Please try again.");
      return false;
    } finally {
      setIsVerifyingTurnstile(false);
    }
  };
  // --- End Verify Turnstile Token

  const resetAll = useCallback(() => {
    setName("");
    setEmail("");
    setOtp("");
    setTosAccepted(false);
    setTurnstileToken(null); // Reset token
    setTurnstileError(null); // Reset error
    setIsVerifyingTurnstile(false); // Reset loading
    resetCognito(); // Reset cognito hook state
    // Note: The Turnstile widget itself might need a reset for a fresh challenge
    // after closing/reopening... might need <Turnstile key=...> / ref.
  }, [resetCognito]);

  // Handle tab switch
  const handleTab = (newTab: Tab) => {
    setTab(newTab);
    resetAll();
  };

  // Sign Up flow
  const handleSignUp = async (e: React.FormEvent) => {
    e.preventDefault();

    console.log(`about to call verify with turnstileToken: {turnstileToken}`)
    const isVerified = await verifyTurnstile(turnstileToken);
    console.log(`isVerified = {isVerified}`)
    if (!isVerified) return;

    const ok = await signUp(email, name, tosAccepted);
    if (ok) {
      await startAuth(email); // trigger OTP
    }
  };

  // Sign In flow
  const handleSignIn = async (e: React.FormEvent) => {
    e.preventDefault();

    console.log(`about to call verify with turnstileToken: {turnstileToken}`)
    const isVerified = await verifyTurnstile(turnstileToken);
    console.log(`isVerified = {isVerified}`)
    if (!isVerified) return;
    if (!isVerified) return;

    await startAuth(email); // trigger OTP
  };

  // OTP
  const handleOtp = async (e: React.FormEvent) => {
    e.preventDefault();
    const authResult = await submitOtp(email, otp);
    if (authResult) {
      login({
        idToken: authResult.IdToken!,
        accessToken: authResult.AccessToken!,
        refreshToken: authResult.RefreshToken!,
      });
      setTimeout(() => {
        resetAll();
        onClose();
      }, 1000);
    }
  };

  const isLoading = cognitoLoading || isVerifyingTurnstile;
  if (!turnstileSiteKey) {
    console.error("NEXT_PUBLIC_TURNSTILE_SITE_KEY is not set.");
    return (
        <Modal open={open} onClose={onClose}>
            <div className="text-red-400 p-4">
                Security check configuration error. Please contact support.
            </div>
        </Modal>
    );
  }

  return (
    <Modal open={open} onClose={() => { resetAll(); onClose(); }}>
      {step === "form" && (
        <div>
          {/* Tabs */}
          <div className="flex mb-4">
            <button
              className={`flex-1 py-2 font-semibold rounded-t ${tab === "signIn" ? "bg-[#23233a] text-[#f7931a]" : "bg-[#181a20] text-white"}`}
              onClick={() => handleTab("signIn")}
              type="button"
              id="signin-tab"
              aria-label="Switch to Sign In"
              disabled={isLoading} // Disable tab switch during loading
            >
              Sign In
            </button>
            <button
              className={`flex-1 py-2 font-semibold rounded-t ${tab === "signUp" ? "bg-[#23233a] text-[#f7931a]" : "bg-[#181a20] text-white"}`}
              onClick={() => handleTab("signUp")}
              type="button"
              id="signup-tab"
              aria-label="Switch to Sign Up"
              disabled={isLoading} // Disable tab switch during loading
            >
              Sign Up
            </button>
          </div>

          {/* Sign Up Form */}
          {tab === "signUp" ? (
            <form onSubmit={handleSignUp} className="flex flex-col gap-4">
              {/* Name Input */}
              <label htmlFor="signup-name" className="text-sm font-medium">
                Name
                <input
                  type="text" name="name" id="signup-name" autoComplete="name"
                  placeholder="Your Name"
                  className="p-2 rounded bg-[#23233a] text-white w-full"
                  value={name} onChange={e => setName(e.target.value)}
                  required aria-label="Full Name" disabled={isLoading}
                />
              </label>
              {/* Email Input */}
              <label htmlFor="signup-email" className="text-sm font-medium">
                Email
                <input
                  type="email" name="email" id="signup-email" autoComplete="email"
                  placeholder="you@email.com"
                  className="p-2 rounded bg-[#23233a] text-white w-full"
                  value={email} onChange={e => setEmail(e.target.value)}
                  required aria-label="Email Address" disabled={isLoading}
                />
              </label>
              {/* TOS Checkbox */}
              <label htmlFor="signup-tos-checkbox" className="flex items-center gap-2">
                <input
                  type="checkbox" name="tos-checkbox" id="signup-tos-checkbox"
                  checked={tosAccepted} onChange={e => setTosAccepted(e.target.checked)}
                  required aria-label="Agree to Terms of Service" disabled={isLoading}
                />
                <span>
                  I agree to the <a href="/terms" target="_blank" rel="noopener noreferrer" className="underline">Terms of Service.</a>
                </span>
              </label>

              {/* Turnstile Widget */}
              <div className="my-2">
                <Turnstile
                  siteKey={turnstileSiteKey}
                  // onVerify={(token) => setTurnstileToken(token)}
                  onVerify={(token) => {
                    console.log("Turnstile Verified! Token:", token);
                    setTurnstileToken(token);
                  }}
                  onError={() => setTurnstileError("Security check failed. Please refresh or try again.")}
                  onExpire={() => setTurnstileToken(null)}
                  // theme="dark"
                  // size="compact"
                />
              </div>

              {/* Turnstile Error Display */}
              {turnstileError && <div className="text-red-400 text-sm">{turnstileError}</div>}

              {/* Submit Button */}
              <button
                type="submit" id="signup-continue-submit"
                className="bg-[#f7931a] text-white font-semibold py-2 rounded hover:bg-[#e07c00] transition disabled:opacity-50 disabled:cursor-not-allowed"
                disabled={isLoading || !tosAccepted || !turnstileToken} // Disable if loading, TOS not accepted, or Turnstile not completed
                aria-label="Sign Up and Continue"
              >
                {isVerifyingTurnstile ? "Verifying..." : cognitoLoading ? "Sending code..." : "Sign Up & Continue"}
              </button>
              {/* Cognito Error Display */}
              {cognitoError && <div className="text-red-400">{cognitoError}</div>}
            </form>
          ) : (
            // Sign In Form
            <form onSubmit={handleSignIn} className="flex flex-col gap-4">
              {/* Email Input */}
              <label htmlFor="signin-email" className="text-sm font-medium">
                Email
                <input
                  type="email" name="email" id="signin-email" autoComplete="email"
                  placeholder="you@email.com"
                  className="p-2 rounded bg-[#23233a] text-white w-full"
                  value={email} onChange={e => setEmail(e.target.value)}
                  required aria-label="Email Address" disabled={isLoading}
                />
              </label>

              {/* Turnstile Widget */}
               <div className="my-2">
                <Turnstile
                  siteKey={turnstileSiteKey}
                  // onVerify={(token) => setTurnstileToken(token)}
                  onVerify={(token) => {
                    console.log("Turnstile Verified! Token:", token);
                    setTurnstileToken(token);
                  }}
                  onError={() => setTurnstileError("Security check failed. Please refresh or try again.")}
                  onExpire={() => setTurnstileToken(null)}
                  // theme="dark"
                  // size="compact"
                />
              </div>

              {/* Turnstile Error Display */}
              {turnstileError && <div className="text-red-400 text-sm">{turnstileError}</div>}

              {/* Submit Button */}
              <button
                type="submit" id="signin-continue-submit"
                className="bg-[#f7931a] text-white font-semibold py-2 rounded hover:bg-[#e07c00] transition disabled:opacity-50 disabled:cursor-not-allowed"
                disabled={isLoading || !turnstileToken} // Disable if loading or Turnstile not completed
                aria-label="Continue"
              >
                 {isVerifyingTurnstile ? "Verifying..." : cognitoLoading ? "Sending code..." : "Continue"}
              </button>
              {/* Cognito Error Display */}
              {cognitoError && <div className="text-red-400">{cognitoError}</div>}
            </form>
          )}
        </div>
      )}

      {/* OTP Step */}
      {step === "otp" && (
        <form onSubmit={handleOtp} className="flex flex-col gap-4">
          <h2 className="text-xl font-bold mb-2">Enter the code sent to your email</h2>
          <label htmlFor="otp-code" className="text-sm font-medium">
            Code
            <input
              type="text" name="otp" id="otp-code" autoComplete="one-time-code"
              placeholder="6-digit code"
              className="p-2 rounded bg-[#23233a] text-white w-full"
              value={otp} onChange={e => setOtp(e.target.value)}
              required maxLength={6} aria-label="One-time code" disabled={cognitoLoading} // Only disable for cognito loading
            />
          </label>
          <button
            type="submit" id="otp-continue-submit"
            className="bg-[#f7931a] text-white font-semibold py-2 rounded hover:bg-[#e07c00] transition disabled:opacity-50 disabled:cursor-not-allowed"
            disabled={cognitoLoading} // Only disable for cognito loading
            aria-label="Verify"
          >
            {cognitoLoading ? "Verifying..." : "Verify"}
          </button>
          {cognitoError && <div className="text-red-400">{cognitoError}</div>}
        </form>
      )}

      {/* Success Step */}
      {step === "success" && (
        <div className="text-green-400 text-center py-8">
          Success! You are signed in.
        </div>
      )}
    </Modal>
  );
}
