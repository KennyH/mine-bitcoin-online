import { createContext, useContext } from "react";

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
