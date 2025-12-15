// esbuild.config.js
const esbuild = require("esbuild");
const { sassPlugin } = require("esbuild-sass-plugin");

// 共通設定
const buildOptions = {
  entryPoints: ["app/javascript/application.js"],
  bundle: true,
  sourcemap: true,
  format: "esm",
  outdir: "app/assets/builds",
  publicPath: "/assets",
  plugins: [sassPlugin()],
};

// watchフラグ付きなら watch モード起動
if (process.argv.includes("--watch")) {
  esbuild.context(buildOptions).then((ctx) => {
    ctx.watch();
    console.log("👀 Watching for changes...");
  });
} else {
  esbuild.build(buildOptions).then(() => {
    console.log("✅ Build completed");
  }).catch(() => process.exit(1));
}
