module.exports = {
    preset: 'ts-jest',
    testEnvironment: "jsdom",
    testMatch: [
        "<rootDir>/src/__tests__/**/*.(spec|test).[jt]s?(x)",
        "<rootDir>/src/**/*.(spec|test).[jt]s?(x)"
      ],
    setupFilesAfterEnv: ["<rootDir>/jest.setup.ts"],
    moduleNameMapper: {
      "^@/(.*)$": "<rootDir>/src/$1",
      "\\.(css|less|scss|sass)$": "identity-obj-proxy"
    },
    globals: {
      'ts-jest': {
        tsconfig: '<rootDir>/tsconfig.jest.json'
      }
    }
  };
  