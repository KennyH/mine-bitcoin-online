export default [
  {
    ignores: [
      "**/.next/**",
      "**/out/**",
      "**/next-env.d.ts",
      "**/node_modules/**"
    ]
  },
  {
    files: ["**/*.js", "**/*.jsx", "**/*.ts", "**/*.tsx"],
    settings: {
      react: {
        // Hardcoding a version silences the "detect" warning in Super-Linter's isolated environment
        version: "18.3.1" 
      }
    },
    rules: {
      "n/no-missing-import": "off",
      "n/no-unsupported-features/node-builtins": "off"
    }
  }
];
