'use client';

import React, { useState, useCallback, useEffect, useRef } from 'react';
import { Turnstile } from 'next-turnstile';
import { useRouter } from 'next/router';
import Modal from './Modal';
import { useCognitoCustomAuth } from '@/hooks/useCognitoCustomAuth';
import { useCognitoUser } from '@/context/CognitoUserContext';

type Tab = "signIn" | "signUp";

const siteKey = process.env.NEXT_PUBLIC_TURNSTILE_SITE_KEY!;
const verifyEndpoint = process.env.NEXT_PUBLIC_TURNSTILE_VERIFICATION_ENDPOINT!;

export default function SignUpModal({
  open,
  onClose,
  createdUser = false,
}: {
  open: boolean;
  onClose: () => void;
  createdUser?: boolean;
}) {
  const [tab, setTab] = useState<Tab>("signUp");
  const [name, setName] = useState("");
  const [email, setEmail] = useState("");
  const [tosAccepted, setTosAccepted] = useState(false);
  const [otp, setOtp] = useState("");
  const nameInputRef = useRef<HTMLInputElement>(null);
  const emailInputRef = useRef<HTMLInputElement>(null);
  const router = useRouter();

  useEffect(()=>{
    setTab(createdUser ? "signIn" : "signUp");
  }, [createdUser]);

  // Cognito
  const {
    step,
    errorMessage: cognitoError,
    errorCode: cognitoErrorCode,
    loading: cognitoLoading,
    signUp,
    startAuth,
    submitOtp,
    reset: resetCognito,
  } = useCognitoCustomAuth();
  const { login } = useCognitoUser();

  // switch to sign up, if user not found
  useEffect(() => {
    if (cognitoErrorCode === "UserNotFound"){
      setTab("signUp");
    }
  }, [cognitoErrorCode]);
  // focus the right field when the modal shows or tab changes
  useEffect(() => {
    if (!open || step !== "form") return;
    if (tab === "signUp")  nameInputRef.current?.focus();
    if (tab === "signIn")  emailInputRef.current?.focus();
  }, [open, tab, step]);

  // Turnstile
  const [turnstileStatus, setTurnstileStatus] = useState<
    "success" | "error" | "expired" | "required"
  >("required");
  const [turnstileToken, setTurnstileToken] = useState<string | null>(null);
  const [turnstileError, setTurnstileError] = useState<string | null>(null);
  const [isVerifyingTurnstile, setIsVerifyingTurnstile] = useState(false);

  const validateTurnstile = async () => {
    if (!turnstileToken) {
      setTurnstileError("Please complete the security check.");
      return false;
    }
    if (process.env.NODE_ENV === "development") {
      return true;
    }

    setIsVerifyingTurnstile(true);
    try {
      const res = await fetch(verifyEndpoint!, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ token: turnstileToken }),
      });
      const json = await res.json();
      if (res.ok && json.success) return true;
      setTurnstileError("Security check failed. Please try again.");
      return false;
    } catch (err) {
      console.error(err);
      setTurnstileError("Error validating security check.");
      return false;
    } finally {
      setIsVerifyingTurnstile(false);
    }
  };

  const resetAll = useCallback(() => {
    setName("");
    setEmail("");
    setOtp("");
    setTosAccepted(false);
    setTurnstileStatus("required");
    setTurnstileToken(null);
    setTurnstileError(null);
    setIsVerifyingTurnstile(false);
    resetCognito();
  }, [resetCognito]);

  const handleTab = (t: Tab) => {
    setTab(t);
    resetAll();
  };

  // Submit flow
  const handleSignUp = async (e: React.FormEvent) => {
    e.preventDefault();
    if (turnstileStatus !== "success") {
      setTurnstileError("Please verify you are not a bot.");
      return;
    }
    if (!(await validateTurnstile())) return;

    if (await signUp(email, name, tosAccepted)) {
      await startAuth(email);
    }
  };

  const handleSignIn = async (e: React.FormEvent) => {
    e.preventDefault();
    if (turnstileStatus !== "success") {
      setTurnstileError("Please verify you are not a bot.");
      return;
    }
    if (!(await validateTurnstile())) return;

    await startAuth(email);
  };

  const handleOtp = async (e: React.FormEvent) => {
    e.preventDefault();
    const auth = await submitOtp(email, otp);
    if (auth) {
      login({
        idToken: auth.IdToken!,
        accessToken: auth.AccessToken!,
        refreshToken: auth.RefreshToken!,
      });

      setTimeout(() => {
        resetAll();
        onClose();
        // handle redirect with possible qs path
        const redirectQuery = router.query.redirect;
        const redirectPath = Array.isArray(redirectQuery) ?
          redirectQuery[0] || '/start' :
          '/start';
        router.push(redirectPath);
      }, 600);
    }
  };

  const handleOtpInputChange = async (e: React.ChangeEvent<HTMLInputElement>) => {
    const value = e.target.value;
    setOtp(value);

    // Check if the input has exactly 6 characters
    if (value.length === 6) {
      const syntheticEvent = {
        preventDefault: () => {},
      } as React.FormEvent;
      handleOtp(syntheticEvent);
    }
  };

  const isLoading = cognitoLoading || isVerifyingTurnstile;
  const btnDisabled = (extra = false) =>
    isLoading ||
    turnstileStatus !== "success" ||
    extra ||
    !!turnstileError;

  return (
    <Modal
      open={open}
      onClose={() => {
        resetAll();
        onClose();
      }}
    >
      {/* ───────────────────────  form step  ──────────────────────── */}
      {step === "form" && (
        <div>
          {/* ──── tab header ──── */}
          <div className="flex mb-4">
            {["signIn", "signUp"].map((t) => (
              <button
                key={t}
                className={`flex-1 py-2 font-semibold rounded-t ${
                  tab === t
                    ? "bg-[#23233a] text-[#f7931a]"
                    : "bg-[#181a20] text-white"
                }`}
                type="button"
                disabled={isLoading}
                onClick={() => handleTab(t as Tab)}
              >
                {t === "signIn" ? "Sign In" : "Sign Up"}
              </button>
            ))}
          </div>

          {/* ──────────────── sign-up ─────────────── */}
          {tab === "signUp" ? (
            <form onSubmit={handleSignUp} className="flex flex-col gap-4">
              <label className="text-sm font-medium">
                Name
                <input
                  className="p-2 rounded bg-[#23233a] text-white w-full text-lg"
                  required
                  disabled={isLoading}
                  value={name}
                  onChange={(e) => setName(e.target.value)}
                  ref={nameInputRef}
                />
              </label>
              <label className="text-sm font-medium">
                Email
                <input
                  className="p-2 rounded bg-[#23233a] text-white w-full text-lg"
                  type="email"
                  required
                  disabled={isLoading}
                  value={email}
                  onChange={(e) => setEmail(e.target.value)}
                />
              </label>
              <label className="flex items-center gap-2">
                <input
                  type="checkbox"
                  required
                  disabled={isLoading}
                  checked={tosAccepted}
                  onChange={(e) => setTosAccepted(e.target.checked)}
                />
                <span>
                  I agree to the{" "}
                  <a href="/docs/terms" className="underline" target="_blank">
                    Terms of Service
                  </a>
                </span>
              </label>

              {/* ──── turnstile for sign up ──── */}
              <Turnstile
                key={open ? "open" : "closed"}
                siteKey={siteKey}
                sandbox={process.env.NODE_ENV === "development"}
                refreshExpired="auto"
                retry="auto"
                theme="dark"
                onError={() => {
                  setTurnstileStatus("error");
                  setTurnstileError("Security check failed. Try again.");
                }}
                onExpire={() => {
                  setTurnstileStatus("expired");
                  setTurnstileError("Security check expired.");
                  setTurnstileToken(null);
                }}
                onLoad={() => {
                  setTurnstileStatus("required");
                  setTurnstileError(null);
                  setTurnstileToken(null);
                }}
                onVerify={(tok) => {
                  setTurnstileStatus("success");
                  setTurnstileError(null);
                  setTurnstileToken(tok);
                }}
              />

              {turnstileError && (
                <div className="text-red-400 text-sm">{turnstileError}</div>
              )}

              <button
                className="bg-[#f7931a] text-white font-semibold py-2 rounded disabled:opacity-50"
                type="submit"
                disabled={btnDisabled(!tosAccepted)}
              >
                {isLoading
                  ? "Verifying..."
                  : cognitoLoading
                  ? "Sending code..."
                  : "Sign Up & Continue"}
              </button>
              {cognitoError && (
                <div className="text-red-400">{cognitoError}</div>
              )}
            </form>
          ) : (
            /* ─────────────────── sign in ──────────────────────── */
            <form onSubmit={handleSignIn} className="flex flex-col gap-4">
              <label className="text-sm font-medium">
                Email
                <input
                  className="p-2 rounded bg-[#23233a] text-white w-full text-lg"
                  type="email"
                  required
                  disabled={isLoading}
                  value={email}
                  onChange={(e) => setEmail(e.target.value)}
                  ref={emailInputRef}
                />
              </label>

              {/* ──── turnstile for sign in ──── */}
              <Turnstile
                key={open ? "open-in" : "closed-in"}
                siteKey={siteKey}
                sandbox={process.env.NODE_ENV === "development"}
                refreshExpired="auto"
                retry="auto"
                theme="dark"
                onError={() => {
                  setTurnstileStatus("error");
                  setTurnstileError("Security check failed. Try again.");
                }}
                onExpire={() => {
                  setTurnstileStatus("expired");
                  setTurnstileError("Security check expired.");
                  setTurnstileToken(null);
                }}
                onLoad={() => {
                  setTurnstileStatus("required");
                  setTurnstileError(null);
                  setTurnstileToken(null);
                }}
                onVerify={(tok) => {
                  setTurnstileStatus("success");
                  setTurnstileError(null);
                  setTurnstileToken(tok);
                }}
              />

              {turnstileError && (
                <div className="text-red-400 text-sm">{turnstileError}</div>
              )}

              <button
                type="submit"
                className="bg-[#f7931a] text-white font-semibold py-2 rounded disabled:opacity-50"
                disabled={btnDisabled()}
              >
                {isLoading
                  ? "Verifying..."
                  : cognitoLoading
                  ? "Sending code..."
                  : "Continue"}
              </button>
              {cognitoError && (
                <div className="text-red-400">{cognitoError}</div>
              )}
            </form>
          )}
        </div>
      )}

      {/* ─────────────────────────── otp ──────────────────────── */}
      {step === "otp" && (
        <form onSubmit={handleOtp} className="flex flex-col gap-4">
          <h2 className="text-xl font-bold mb-2">
            Enter the code sent to your email
          </h2>
          <label className="text-sm font-medium">
            Code
            <input
              type="text"
              maxLength={6}
              required
              disabled={cognitoLoading}
              value={otp}
              onChange={handleOtpInputChange}
              className="p-2 rounded bg-[#23233a] text-white w-full text-lg"
              autoFocus
            />
          </label>
          <button
            type="submit"
            disabled={cognitoLoading || otp.length !== 6}
            className="bg-[#f7931a] text-white font-semibold py-2 rounded disabled:opacity-50"
          >
            {cognitoLoading ? "Verifying..." : "Verify"}
          </button>
          {cognitoError && (
            <div className="text-red-400">{cognitoError}</div>
          )}
        </form>
      )}

      {/* ───────────────────────── success ──────────────────────────── */}
      {step === "success" && (
        <div className="text-green-400 text-center py-8">
          Success! You are signed in.
        </div>
      )}
    </Modal>
  );
}
