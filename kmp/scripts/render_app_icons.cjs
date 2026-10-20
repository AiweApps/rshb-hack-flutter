// Optional design exports. Requires Node and Sharp; no Android runtime dependency.
const fs = require('node:fs');
const path = require('node:path');
const sharp = require('sharp');
const base = path.resolve(__dirname, '../design/icons');
const registry = JSON.parse(fs.readFileSync(path.join(base, 'icons.json'), 'utf8'));

async function main() {
  fs.mkdirSync(path.join(base, 'png'), { recursive: true });
  const cells = [];
  let index = 0;
  for (const [name, icon] of Object.entries(registry.icons)) {
    await sharp(path.join(base, 'svg', `${name}.svg`), { density: 576 })
      .resize(192, 192).png().toFile(path.join(base, 'png', `${name}.png`));
    const x = index % 7 * 170;
    const y = Math.floor(index / 7) * 160;
    cells.push(`<rect x="${x + 10}" y="${y + 10}" width="150" height="142" rx="16" fill="white" stroke="#dedbd6"/>
      <g transform="translate(${x + 57} ${y + 34}) scale(2.3)" style="color:#292725">
        ${fs.readFileSync(path.join(base, 'svg', `${name}.svg`), 'utf8').replace(/<svg[^>]*>/, '').replace('</svg>', '')}</g>
      <text x="${x + 85}" y="${y + 124}" font-family="Arial" text-anchor="middle"
        font-size="13" fill="#4c4844">${name}</text>`);
    index++;
  }
  const height = Math.ceil(index / 7) * 160;
  const svg = `<svg xmlns="http://www.w3.org/2000/svg" width="1190" height="${height}">
    <rect width="1190" height="${height}" fill="#f6f4f0"/>${cells.join('')}</svg>`;
  fs.writeFileSync(path.join(base, 'contact-sheet.svg'), svg);
  await sharp(Buffer.from(svg)).png().toFile(path.join(base, 'contact-sheet.png'));
  console.log(`Rendered ${index} PNG icons and contact sheet`);
}
main().catch(error => { console.error(error); process.exitCode = 1; });
