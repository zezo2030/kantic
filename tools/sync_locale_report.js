const fs = require("fs");
const path = require("path");

const root = path.join(__dirname, "..", "assets", "translations");
const en = JSON.parse(fs.readFileSync(path.join(root, "en.json"), "utf8"));
const ar = JSON.parse(fs.readFileSync(path.join(root, "ar.json"), "utf8"));
const enKeys = Object.keys(en);
const arKeys = Object.keys(ar);
const inEnNotAr = enKeys.filter((k) => !(k in ar)).sort();
const inArNotEn = arKeys.filter((k) => !(k in en)).sort();

console.log(JSON.stringify({
  enCount: enKeys.length,
  arCount: arKeys.length,
  missingInAr: inEnNotAr.length,
  missingInEn: inArNotEn.length,
  sampleMissingInAr: inEnNotAr.slice(0, 25),
  sampleMissingInEn: inArNotEn.slice(0, 25),
}, null, 2));
