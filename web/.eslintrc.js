module.exports = {
    env: { node: true },
    extends: [
        "eslint:recommended",
        "plugin:@typescript-eslint/recommended",
        "plugin:prettier/recommended",
    ],
    plugins: ["@typescript-eslint"],
    overrides: [
        {
            files: ["**/*.ts"],
        },
    ],
};
