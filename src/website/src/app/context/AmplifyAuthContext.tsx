'use client';

import React, { createContext, useContext, useEffect, useState } from 'react';
import { signInWithRedirect, signOut, getCurrentUser, fetchAuthSession, type AuthUser, signIn } from 'aws-amplify/auth';

interface AmplifyAuthContextProps {
    user: AuthUser | null;
    email: string | null;
    loading: boolean;
    login: () => void;
    logout: () => void; 
}

const AmplifyAuthContext = createContext<AmplifyAuthContextProps | undefined>(undefined);

export const useAuth = (): AmplifyAuthContextProps => {
    const context = useContext(AmplifyAuthContext);
    if (!context) {
        throw new Error('useAuth must be used within AmplifyAuthProvider');
    }
    return context;
}

export function AmplifyAuthProvider({ children }: { children: React.ReactNode }) {
    const [user, setUser] = useState<AuthUser | null>(null);
    const [email, setEmail] = useState<string | null>(null);
    const [loading, setLoading] = useState(true);

    useEffect(() => {
        const checkUser = async () => {
            try {
                const currentUser = await getCurrentUser();
                setUser(currentUser);

                const session = await fetchAuthSession();
                const idTokenPayload = session.tokens?.idToken?.payload;
                const email = idTokenPayload?.email;
                setEmail(typeof email === 'string' ? email : null);
            } catch {
                setUser(null);
                setEmail(null);
            } finally {
                setLoading(false);
            }
        };
        checkUser();
    }, []);

    const login = () => signInWithRedirect();
    const logout = () => signOut().then(() => {
        setUser(null);
        setEmail(null);
    });

    return (<
        AmplifyAuthContext.Provider value={{ user, email, loading, login, logout }}>
        {children}
      </AmplifyAuthContext.Provider>
    );
}

