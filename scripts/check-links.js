// 检查站内相对链接是否都指向真实文件（首页、404、各 App 索引页）
const fs = require('fs');
const path = require('path');

const root = path.resolve(__dirname, '..');
const pages = ['index.html', '404.html'].concat(
  fs.readdirSync(root, { withFileTypes: true })
    .filter((d) => d.isDirectory() && fs.existsSync(path.join(root, d.name, 'index.html')))
    .map((d) => `${d.name}/index.html`)
);

let checked = 0;
const missing = [];

for (const page of pages) {
  const html = fs.readFileSync(path.join(root, page), 'utf8');
  const dir = path.dirname(path.join(root, page));
  for (const m of html.matchAll(/(?:href|src)="([^"]+)"/g)) {
    const url = m[1];
    if (/^(https?:|mailto:|#)/.test(url)) continue;
    checked++;
    const target = url.startsWith('/')
      ? path.join(root, url.replace(/^\/PrivatePolicy\/?/, ''))
      : path.join(dir, url);
    if (!fs.existsSync(target)) missing.push(`${page} -> ${url}`);
  }
}

console.log(`pages: ${pages.length}, links: ${checked}, missing: ${missing.length}`);
for (const line of missing) console.log('  ' + line);

// 每个 App 目录必须有的入口文件
for (const slug of ['morse-craft', 'id-photo-maker', 'md-reader', 'any-convert']) {
  for (const file of ['index.html', 'privacy.html', 'terms.html']) {
    if (!fs.existsSync(path.join(root, slug, file))) missing.push(`${slug}/${file} missing`);
  }
}

// 条款文件必须是完整 HTML
for (const slug of ['morse-craft', 'id-photo-maker', 'md-reader', 'any-convert']) {
  for (const file of fs.readdirSync(path.join(root, slug)).filter((f) => f.endsWith('.html'))) {
    const body = fs.readFileSync(path.join(root, slug, file), 'utf8');
    if (!/<\/html>\s*$/i.test(body)) console.log(`  warn: ${slug}/${file} 结尾不像完整 HTML`);
  }
}

process.exitCode = missing.length ? 1 : 0;
