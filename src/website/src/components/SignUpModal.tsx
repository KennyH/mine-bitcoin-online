"use client";

import React, { useState } from 'react';
import Modal from './Modal';
import { useCognitoCustomAuth } from '@/hooks/useCognitoCustomAuth';
import { useCognitoUser } from '@/context/CognitoUserContext';

type Tab = "signIn" | "signUp";

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
  const {
    step,
    error,
    loading,
    signUp,
    startAuth,
    submitOtp,
    reset,
  } = useCognitoCustomAuth();
  const { login } = useCognitoUser();

  // Handle tab switch
  const handleTab = (tab: Tab) => {
    setTab(tab);
    setName("");
    setEmail("");
    setOtp("");
    reset();
  };

  // Sign Up flow
  const handleSignUp = async (e: React.FormEvent) => {
    e.preventDefault();
    const ok = await signUp(email, name, tosAccepted);
    if (ok) {
      await startAuth(email);
    }
  };

  // Sign In flow
  const handleSignIn = async (e: React.FormEvent) => {
    e.preventDefault();
    await startAuth(email);
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
        reset();
        onClose();
      }, 1000);
    }
  };

  return (
    <Modal open={open} onClose={() => { reset(); onClose(); }}>
      {step === "form" && (
        <div>
          <div className="flex mb-4">
            <button
              className={`flex-1 py-2 font-semibold rounded-t ${tab === "signIn" ? "bg-[#23233a] text-[#f7931a]" : "bg-[#181a20] text-white"}`}
              onClick={() => handleTab("signIn")}
              type="button"
              name="signin-tab"
              id="signin-tab"
            >
              Sign In
            </button>
            <button
              className={`flex-1 py-2 font-semibold rounded-t ${tab === "signUp" ? "bg-[#23233a] text-[#f7931a]" : "bg-[#181a20] text-white"}`}
              onClick={() => handleTab("signUp")}
              type="button"
              name="signup-tab"
              id="signup-tab"
            >
              Sign Up
            </button>
          </div>
          {tab === "signUp" ? (
            <form onSubmit={handleSignUp} className="flex flex-col gap-4">
              <input
                type="text"
                name="name"
                id="signup-name"
                autoComplete="name"
                placeholder="Name"
                className="p-2 rounded bg-[#23233a] text-white"
                value={name}
                onChange={e => setName(e.target.value)}
                required
              />
              <input
                type="email"
                name="email"
                id="signup-email"
                autoComplete="email"
                placeholder="Email"
                className="p-2 rounded bg-[#23233a] text-white"
                value={email}
                onChange={e => setEmail(e.target.value)}
                required
              />
              <label className="flex items-center gap-2">
              <input
                type="checkbox"
                name="tos-checkbox"
                id="signup-tos-checkbox"
                checked={tosAccepted}
                onChange={e => setTosAccepted(e.target.checked)}
                required
              />
              <span>
                I agree to the <a href="/terms" target="_blank" rel="noopener noreferrer" className="underline">Terms of Service.</a>
              </span>
            </label>
              <button
                type="submit"
                name="continue-submit"
                id="signup-continue-submit"
                className="bg-[#f7931a] text-white font-semibold py-2 rounded hover:bg-[#e07c00] transition"
                disabled={loading || !tosAccepted}
              >
                {loading ? "Sending code..." : "Sign Up & Continue"}
              </button>
              {error && <div className="text-red-400">{error}</div>}
            </form>
          ) : (
            <form onSubmit={handleSignIn} className="flex flex-col gap-4">
              <input
                type="email"
                name="email"
                id="signin-email"
                autoComplete="email"
                placeholder="Email"
                className="p-2 rounded bg-[#23233a] text-white"
                value={email}
                onChange={e => setEmail(e.target.value)}
                required
              />
              <button
                type="submit"
                name="continue-submit"
                id="signip-continue-submit"
                className="bg-[#f7931a] text-white font-semibold py-2 rounded hover:bg-[#e07c00] transition"
                disabled={loading}
              >
                {loading ? "Sending code..." : "Continue"}
              </button>
              {error && <div className="text-red-400">{error}</div>}
            </form>
          )}
        </div>
      )}
      {step === "otp" && (
        <form onSubmit={handleOtp} className="flex flex-col gap-4">
          <h2 className="text-xl font-bold mb-2">Enter the code sent to your email</h2>
          <input
            type="text"
            name="otp"
            id="otp-code"
            autoComplete="one-time-code"
            placeholder="6-digit code"
            className="p-2 rounded bg-[#23233a] text-white"
            value={otp}
            onChange={e => setOtp(e.target.value)}
            required
            maxLength={6}
          />
          <button
            type="submit"
            name="otp-submit"
            id="otp-continue-submit"
            className="bg-[#f7931a] text-white font-semibold py-2 rounded hover:bg-[#e07c00] transition"
            disabled={loading}
          >
            {loading ? "Verifying..." : "Verify"}
          </button>
          {error && <div className="text-red-400">{error}</div>}
        </form>
      )}
      {step === "success" && (
        <div className="text-green-400 text-center py-8">
          Success! You are signed in.
        </div>
      )}
    </Modal>
  );
}
