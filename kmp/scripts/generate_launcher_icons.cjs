#!/usr/bin/env node
// Approved D2 artwork; Sharp is a development-only export dependency.
const fs = require('node:fs');
const path = require('node:path');
const sharp = require('sharp');
const root = path.resolve(__dirname, '..');
const design = path.join(root, 'design/launcher');
const res = path.join(root, 'androidApp/src/main/res');
const ios = path.join(root, 'iosApp/iosApp/Assets.xcassets');
const approved = path.join(design, 'd2-approved.png');
const background = '#650014';
const xml = '<?xml version="1.0" encoding="utf-8"?>\n';
function write(name, value) {
  const file = path.join(res, name);
  fs.mkdirSync(path.dirname(file), { recursive: true });
  fs.writeFileSync(file, value);
}
async function masked(input, shape, size) {
  const svg = `<svg xmlns="http://www.w3.org/2000/svg" width="${size}" height="${size}">` +
    (shape === 'circle' ? `<circle cx="${size / 2}" cy="${size / 2}" r="${size / 2}" fill="white"/>` :
      `<rect width="${size}" height="${size}" rx="${size * .23}" fill="white"/>`) + '</svg>';
  return sharp(await sharp(input).resize(size, size).png().toBuffer())
    .composite([{ input: Buffer.from(svg), blend: 'dest-in' }]).png().toBuffer();
}
async function main() {
  // Keep the untrimmed glass placement. Alpha >8 excludes negligible extraction noise.
  const layer = await sharp(path.join(design, 'd2-glass.png')).resize(740, 740).png().toBuffer();
  const foreground = await sharp({ create: { width: 1080, height: 1080,
    channels: 4, background: '#00000000' } })
    .composite([{ input: layer, left: 170, top: 170 }]).png().toBuffer();
  const { data, info } = await sharp(foreground).ensureAlpha().raw().toBuffer({ resolveWithObject: true });
  let radius = 0;
  for (let y = 0; y < info.height; y++) for (let x = 0; x < info.width; x++) {
    if (data[(y * info.width + x) * 4 + 3] > 8)
      radius = Math.max(radius, Math.hypot((x + .5) / 10 - 54, (y + .5) / 10 - 54));
  }
  if (radius > 33) throw Error(`D2 foreground exceeds safe circle: ${radius.toFixed(2)}dp`);
  const raster = path.join(res, 'drawable-nodpi');
  fs.mkdirSync(raster, { recursive: true });
  await sharp(foreground).resize(432, 432).png().toFile(path.join(raster, 'launcher_glass.png'));
  const bitmap = xml + '<bitmap xmlns:android="http://schemas.android.com/apk/res/android" android:src="@drawable/launcher_glass" android:gravity="fill" android:filter="true" />\n';
  write('drawable/ic_launcher_foreground.xml', bitmap);
  write('drawable/app_logo.xml', bitmap);
  write('drawable/ic_launcher_background.xml', xml + `<shape xmlns:android="http://schemas.android.com/apk/res/android" android:shape="rectangle"><solid android:color="${background}" /></shape>\n`);
  const mono = fs.readFileSync(path.join(design, 'd2-monochrome.svg'), 'utf8');
  const paths = [...mono.matchAll(/<path\s+d="([^"]+)"\s*\/>/g)].map(m => m[1]);
  if (paths.length !== 3) throw Error('Expected three D2 monochrome paths');
  write('drawable/ic_launcher_monochrome.xml', xml + '<vector xmlns:android="http://schemas.android.com/apk/res/android" android:width="108dp" android:height="108dp" android:viewportWidth="108" android:viewportHeight="108">\n' +
    paths.map(d => `    <path android:pathData="${d}" android:fillColor="#00000000" android:strokeColor="#FFFFFFFF" android:strokeWidth="2.8" android:strokeLineCap="round" android:strokeLineJoin="round" />`).join('\n') + '\n</vector>\n');
  for (const version of ['26', '33']) for (const name of ['ic_launcher', 'ic_launcher_round'])
    write(`mipmap-anydpi-v${version}/${name}.xml`, xml + '<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">\n' +
      '    <background android:drawable="@drawable/ic_launcher_background" />\n    <foreground android:drawable="@drawable/ic_launcher_foreground" />\n' +
      (version === '33' ? '    <monochrome android:drawable="@drawable/ic_launcher_monochrome" />\n' : '') + '</adaptive-icon>\n');
  for (const [density, size] of Object.entries({ mdpi: 48, hdpi: 72, xhdpi: 96, xxhdpi: 144, xxxhdpi: 192 })) {
    for (const [name, shape] of [['ic_launcher', 'squircle'], ['ic_launcher_round', 'circle']])
      write(`mipmap-${density}/${name}.png`, await masked(approved, shape, size));
  }
  const set = path.join(ios, 'AppIcon.appiconset');
  const done = new Set();
  for (const image of JSON.parse(fs.readFileSync(path.join(set, 'Contents.json'))).images) {
    if (!image.filename || done.has(image.filename)) continue;
    done.add(image.filename);
    const size = Math.round(parseFloat(image.size) * parseFloat(image.scale));
    await sharp(approved).resize(size, size).flatten({ background }).removeAlpha().png()
      .toFile(path.join(set, image.filename));
  }
  for (const [scale, suffix] of [[1, ''], [2, '@2x'], [3, '@3x']])
    fs.writeFileSync(path.join(ios, `LaunchLogo.imageset/launch_logo${suffix}.png`),
      await masked(approved, 'squircle', 120 * scale));
  const index = process.argv.indexOf('--preview');
  if (index !== -1) {
    const output = path.resolve(process.argv[index + 1]);
    fs.mkdirSync(path.dirname(output), { recursive: true });
    const canvas = await sharp({ create: { width: 1080, height: 1080, channels: 4, background } })
      .composite([{ input: foreground }]).png().toBuffer();
    const adaptive = await sharp(canvas)
      .extract({ left: 180, top: 180, width: 720, height: 720 }).png().toBuffer();
    const items = [];
    for (const [i, shape] of ['circle', 'squircle'].entries())
      for (const [j, size] of [48, 192].entries())
        items.push({ input: await masked(adaptive, shape, size), left: 24 + i * 240, top: 24 + j * 76 });
    items.push({ input: await masked(approved, 'squircle', 192), left: 504, top: 100 });
    await sharp({ create: { width: 720, height: 316, channels: 4, background: '#F4F4F6' } })
      .composite(items).png().toFile(output);
  }
  console.log(`D2 Android+iOS exports; significant-alpha safe radius ${radius.toFixed(2)}dp <33dp`);
}
main().catch(error => { console.error(error.message); process.exitCode = 1; });
