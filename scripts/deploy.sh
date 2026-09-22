#!/usr/bin/env bash
set -euo pipefail
node <<'NODE'
const {execFileSync} = require("node:child_process");
const fs = require("node:fs");
const config = fs.readFileSync("wrangler.toml", "utf8");
const required = ["SKINLOOP_API_BASE_URL","SKINLOOP_HOSTED_ORIGIN","KOMERZA_STORE_ID","SHOP_URL"];
for (const key of required) {
  const m = config.match(new RegExp("^"+key+"\\s*=\\s*\"([^\"]+)\"", "m"));
  if (!m || !m[1] || /example|replace|YOUR/i.test(m[1])) throw new Error(`Missing safe variable ${key}`);
}
const listed = JSON.parse(execFileSync("wrangler", ["secret","list","--json"], {encoding:"utf8"}));
const names = new Set((Array.isArray(listed) ? listed : listed.secrets || []).map(x => x.name));
for (const key of ["SKINLOOP_API_KEY","KOMERZA_API_KEY"])
  if (!names.has(key)) throw new Error(`Missing encrypted secret ${key}; run wrangler secret put ${key}`);
execFileSync("wrangler", ["deploy"], {stdio:"inherit"});
NODE