const { createRequire } = require("node:module");
const { realpathSync } = require("node:fs");

async function main() {
  const prettier = createRequire(realpathSync(process.argv[2]))("prettier");
  const options =
    (await prettier.resolveConfig(process.argv[3], { editorconfig: true })) ||
    {};
  process.stdout.write(
    JSON.stringify({
      width: options.tabWidth ?? 2,
      tabs: options.useTabs ?? false,
    }),
  );
}

main().catch((error) => {
  process.stderr.write(String(error));
  process.exitCode = 1;
});
