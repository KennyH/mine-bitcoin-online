/**
 * @fileoverview Defines a React Context (`LayoutContext`) for managing
 * layout-related state across the application.
 *
 * Exports:
 * - `LayoutContextType`: The type definition for the context data.
 * - `LayoutContext`: The React Context object itself, initialized with
 *   default values.
 * - `useLayoutContext`: A custom hook for consuming the `LayoutContext`
 *   in functional components.
 * - `withLayoutContext`: A Higher-Order Component (HOC) for injecting
 *   the `LayoutContext` data as a `layout` prop into class or functional
 *   components.
 */
'use client';

import { createContext, useContext } from 'react';

export type LayoutContextType = {
  showBanner: boolean;
  showTagline: boolean;
};

export const LayoutContext = createContext<LayoutContextType>({
  showBanner: true,
  showTagline: false,
});

export function useLayoutContext() {
  return useContext(LayoutContext);
}

export function withLayoutContext<TProps>(
  Component: React.ComponentType<TProps & { layout: LayoutContextType }>
) {
  return function WrapperComponent(props: TProps) {
    const layout = useLayoutContext();
    return <Component {...props} layout={layout} />;
  };
}
