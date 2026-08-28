import { RuleTester } from "oxlint/plugins-dev";

import { noAmbientEnvAccessRule } from "../assets/no-slop/rules/no-ambient-env-access.ts";
import { noBroadReturnTypesRule } from "../assets/no-slop/rules/no-broad-return-types.ts";
import { noBroadTypeAliasesRule } from "../assets/no-slop/rules/no-broad-type-aliases.ts";

const tester = new RuleTester({ languageOptions: { parserOptions: { lang: "ts" } } });

tester.run("no-slop/no-broad-type-aliases", noBroadTypeAliasesRule, {
  valid: [
    "type User = { readonly id: string };",
    "type ExternalValue = unknown;",
    "type JsonValue = string | number | boolean | null;",
  ],
  invalid: [
    { code: "type Value = any;", errors: [{ messageId: "broadAlias" }] },
    { code: "type Value = object;", errors: [{ messageId: "broadAlias" }] },
    { code: "type Value = ({});", errors: [{ messageId: "broadAlias" }] },
  ],
});

tester.run("no-slop/no-broad-return-types", noBroadReturnTypesRule, {
  valid: [
    "function load(): User { return user; }",
    "function decode(): unknown { return input; }",
    "const load = () => ({ id: 'one' });",
  ],
  invalid: [
    { code: "function load(): any { return input; }", errors: [{ messageId: "broadReturn" }] },
    { code: "const load = (): object => ({});", errors: [{ messageId: "broadReturn" }] },
    { code: "declare function load(): {};", errors: [{ messageId: "broadReturn" }] },
    { code: "type Loader = () => object;", errors: [{ messageId: "broadReturn" }] },
    { code: "interface Loader { load(): any }", errors: [{ messageId: "broadReturn" }] },
  ],
});

tester.run("no-slop/no-ambient-env-access", noAmbientEnvAccessRule, {
  valid: [
    "const process = { env: config }; use(process.env);",
    "function load(process: ProcessLike) { return process.env; }",
    "const env = config.env;",
  ],
  invalid: [
    { code: "const port = process.env.PORT;", errors: [{ messageId: "ambientEnv" }] },
    { code: "const port = process['env'].PORT;", errors: [{ messageId: "ambientEnv" }] },
  ],
});
