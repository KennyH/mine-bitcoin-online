'use client';

import { useEffect } from 'react';
import { Amplify } from 'aws-amplify';

export default function AmplifyConfig() {
  useEffect(() => {
    Amplify.configure({
      Auth: {
        Cognito: {
          userPoolId: process.env.NEXT_PUBLIC_COGNITO_USER_POOL_ID!,
          userPoolClientId: process.env.NEXT_PUBLIC_COGNITO_CLIENT_ID!,
          loginWith: {
            oauth: {
              domain: process.env.NEXT_PUBLIC_COGNITO_DOMAIN!,
              scopes: ['openid', 'email', 'profile'],
              redirectSignIn: [process.env.NEXT_PUBLIC_NEXTAUTH_URL!],
              redirectSignOut: [process.env.NEXT_PUBLIC_NEXTAUTH_URL!],
              responseType: 'code',
            },
          },
        },
      },
    });
  }, []);

  return null;
}
