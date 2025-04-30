"use client";

import React, { createContext, useContext, useEffect, useState } from "react";
import {
  CognitoIdentityProviderClient,
  GetUserCommand,
} from "@aws-sdk/client-cognito-identity-provider";

const REGION = process.env.NEXT_PUBLIC_AWS_REGION!;
const CLIENT_ID = process.env.NEXT_PUBLIC_COGNITO_CLIENT_ID!;

const client = new CognitoIdentityProviderClient({ region: REGION });

type User = {
  email: string;
  name?: string;
  [key: string]: any;
};
  
type CognitoUserContextType = {
  user: User | null;
  loading: boolean;
  login: (tokens: { idToken: string; accessToken: string; refreshToken: string }) => void;
  logout: () => void;
  setUser: React.Dispatch<React.SetStateAction<User | null>>;
};

const CognitoUserContext = createContext<CognitoUserContextType | undefined>(undefined);

export const useCognitoUser = () => {
  const ctx = useContext(CognitoUserContext);
  if (!ctx) throw new Error("useCognitoUser must be used within CognitoUserProvider");
  return ctx;
}

export const CognitoUserProvider = ({ children }: { children: React.ReactNode }) => {
  const [user, setUser] = useState<User | null>(null);
  const [loading, setLoading] = useState(true);
  
  const getTokens = () => {
    try {
      const tokens = localStorage.getItem("cognito_tokens");
      return tokens ? JSON.parse(tokens) : null;
    } catch {
      return null;
    }
  };
  
  const saveTokens = (tokens: any) => {
    localStorage.setItem("cognito_tokens", JSON.stringify(tokens));
  };
  
  const clearTokens = () => {
    localStorage.removeItem("cognito_tokens");
  };
  
  const fetchUser = async (accessToken: string) => {
    try {
      const cmd = new GetUserCommand({ AccessToken: accessToken });
      const res = await client.send(cmd);
      const attrs: Record<string, string> = {};
      res.UserAttributes?.forEach(attr => {
        if (attr.Name && attr.Value) attrs[attr.Name] = attr.Value;
      });
      setUser({
        email: attrs.email,
        name: attrs.name,
        ...attrs,
      });
    } catch (err) {
      setUser(null);
      clearTokens();
    }
  };
  
  // Check for tokens and fetch user
  useEffect(() => {
    const tokens = getTokens();
    if (tokens?.accessToken) {
      fetchUser(tokens.accessToken).finally(() => setLoading(false));
    } else {
      setUser(null);
      setLoading(false);
    }
    // eslint-disable-next-line
  }, []);
  
  // After successful login (after OTP)
  const login = (tokens: { idToken: string; accessToken: string; refreshToken: string }) => {
    saveTokens(tokens);
    fetchUser(tokens.accessToken);
  };
  
  const logout = () => {
    clearTokens();
    setUser(null);
  };

  return (
    <CognitoUserContext.Provider value={{ user, loading, login, logout, setUser }}>
      {children}
    </CognitoUserContext.Provider>
  );
};