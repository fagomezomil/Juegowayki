/* ============================================================
   OPTIMIZAR FOTOS — pipeline del prototipo
   Flujito del Juego del Verano: fotos-originales/ → assets/fotos/ (WebP)
   ============================================================
   Uso:
     1. Tirar las fotos en juego/prototipo/fotos-originales/
        Nombrarlas por ID de sello: A1.jpg, A1-2.jpg, C12.jpg ...
        (el sufijo -2, -3... es el orden de miniaturas)
     2. node optimizar-fotos.cjs
   Qué hace:
     - Convierte a WebP q80, max 1440 px de ancho (metadata fuera, EXIF rotate)
     - Genera assets/fotos.js con el mapa FOTOS y lo pega al diario
     - Borra de assets/fotos/ los sobrantes que ya no tienen origen
     - Re-arma _deploy/ para subir a Netlify
   ============================================================ */
const fs = require('fs');
const path = require('path');
const sharp = require('sharp');

const ROOT = __dirname;
const SRC = path.join(ROOT, 'fotos-originales');
const OUT = path.join(ROOT, 'assets', 'fotos');
const DEPLOY = path.join(ROOT, '_deploy');
const MAXW = 1440, Q = 80;
const EXTS_IN = new Set(['.jpg', '.jpeg', '.png', '.webp', '.tif', '.tiff', '.bmp']);

const kb = n => (n / 1024).toFixed(0) + ' KB';

async function main() {
  fs.mkdirSync(SRC, { recursive: true });
  fs.mkdirSync(OUT, { recursive: true });

  /* IDs de sello tomados del propio index.html (S('A1',...) ) */
  const ids = new Set();
  const html = fs.readFileSync(path.join(ROOT, 'index.html'), 'utf8');
  for (const m of html.matchAll(/S\('([A-Z]\d*)'/g)) ids.add(m[1]);

  /* inventario de originales: base ID + número de orden */
  const items = [];
  for (const f of fs.readdirSync(SRC)) {
    const ext = path.extname(f).toLowerCase();
    if (!EXTS_IN.has(ext)) { console.log('· ignorado (no es foto): ' + f); continue; }
    const stem = path.basename(f, path.extname(f));
    const m = stem.match(/^(.+?)\s*[\(\-]\s*(\d+)\s*\)?\s*$/);
    const base = (m ? m[1] : stem).replace(/[\s.]+/g, '').toUpperCase();
    const n = m ? parseInt(m[2], 10) : 1;
    if (!ids.has(base)) { console.log('⚠ "' + f + '" no matchea ningún ID de sello (¿falta el prefijo ' + base + '?) — se procesa igual'); items.push({ f, base: 'ZZ-' + base, n, warn: true }); continue; }
    items.push({ f, base, n, hasSuffix: !!m, src: path.join(SRC, f) });
  }
  /* sin número = foto principal del sello: va primero */
  items.sort((a, b) => a.base.localeCompare(b.base, 'en') || (a.hasSuffix ? 1 : 0) - (b.hasSuffix ? 1 : 0) || a.n - b.n || a.f.localeCompare(b.f, 'en'));
  /* colisiones: dos originales con el mismo base+n (ej. B3.jpeg y B3.JPG) → n secuencial */
  const visto = {};
  for (const it of items) {
    if (it.warn) continue;
    const k = it.base + ':' + it.n;
    if (visto[k]) { let x = it.n + 1; while (visto[it.base + ':' + x]) x++; it.n = x; }
    visto[it.base + ':' + it.n] = 1;
  }
  if (!items.length) { console.log('No hay fotos en fotos-originales/ — nada para hacer.'); return; }

  /* manifiesto: si un original ya se procesó (nombre+mtime+tamaño) no se re-encodea.
     Esto y NO la fecha del output: Windows copia archivos con su fecha vieja y
     el output de hoy siempre "parece más nuevo" — se salteaban fotos nuevas. */
  const mfPath = path.join(ROOT, '_fotos_manifest.json');
  const mf = fs.existsSync(mfPath) ? JSON.parse(fs.readFileSync(mfPath, 'utf8')) : {};

  const FOTOS = {};
  let bytesIn = 0, bytesOut = 0, hechos = 0, saltadas = 0, fallos = 0;

  for (const it of items) {
    const srcPath = path.join(SRC, it.f);
    const outName = (it.base.toLowerCase() + (it.n > 1 ? '-' + it.n : '')) + '.webp';
    const outPath = path.join(OUT, outName);
    const stIn = fs.statSync(srcPath);
    const prev = mf[it.f];
    if (prev && prev.mtime === stIn.mtimeMs && prev.size === stIn.size && fs.existsSync(path.join(OUT, path.basename(prev.out)))) {
      const sz = fs.statSync(path.join(OUT, path.basename(prev.out))).size;
      saltadas++; bytesIn += stIn.size; bytesOut += sz;
      (FOTOS[it.base] = FOTOS[it.base] || []).push('assets/fotos/' + outName);
      mf[it.f].out = outName; /* la numeración pudo haber cambiado */
      console.log('· sin cambios: ' + it.f);
      continue;
    }
    try {
      const buf = await sharp(srcPath)
        .rotate()
        .resize({ width: MAXW, height: MAXW, fit: 'inside', withoutEnlargement: true })
        .webp({ quality: Q, effort: 4 })
        .toBuffer();
      fs.writeFileSync(outPath, buf);
      hechos++;
      bytesIn += stIn.size; bytesOut += buf.length;
      mf[it.f] = { out: outName, mtime: stIn.mtimeMs, size: stIn.size };
      (FOTOS[it.base] = FOTOS[it.base] || []).push('assets/fotos/' + outName);
      const tag = it.base.startsWith('ZZ-') ? ' ⚠ sin match' : '';
      console.log('→ ' + it.f.padEnd(28) + kb(stIn.size).padStart(9) + ' → ' + kb(buf.length).padStart(6) + tag);
    } catch (e) {
      fallos++; console.log('✕ FALLA ' + it.f + ': ' + e.message);
      if (/heif/i.test(e.message) || /unsupported/i.test(e.message)) console.log('   (si es .HEIC de celular, exportalo a JPG o WhatsApp-documento antes de tirarlo)');
    }
  }
  /* limpiar el manifiesto de originales que ya no están */
  const nombresSrc = new Set(items.map(i => i.f));
  for (const k of Object.keys(mf)) if (!nombresSrc.has(k)) delete mf[k];
  fs.writeFileSync(mfPath, JSON.stringify(mf, null, 1), 'utf8');

  /* sobrantes: webp que ya no sale de ningún original */
  const validos = new Set(Object.values(FOTOS).flat());
  let borrados = 0;
  for (const f of fs.readdirSync(OUT)) {
    if (f.endsWith('.webp') && !validos.has('assets/fotos/' + f)) {
      fs.unlinkSync(path.join(OUT, f)); borrados++;
      console.log('· sobrante borrado: ' + f);
    }
  }

  console.log('\nResumen: ' + hechos + ' optimizadas, ' + saltadas + ' sin cambios, ' + fallos + ' con fallo, ' + borrados + ' sobrantes borrados');
  console.log('Peso original: ' + kb(bytesIn) + ' → optimizado: ' + kb(bytesOut) + ' (' + (bytesIn ? Math.round((1 - bytesOut / bytesIn) * 100) : 0) + '% menos)');

  /* fotos.js: mapa + parche automático sobre SELLOS */
  const js = '/* generado por optimizar-fotos.cjs — no editar a mano */\n' +
    'const FOTOS=' + JSON.stringify(FOTOS, null, 1) + ';\n' +
    "if(typeof SELLOS!=='undefined')SELLOS.forEach(s=>{if(FOTOS[s.id])s.fotos=FOTOS[s.id]});\n";
  fs.writeFileSync(path.join(ROOT, 'assets', 'fotos.js'), js, 'utf8');
  console.log('\nassets/fotos.js escrito (' + Object.keys(FOTOS).length + ' sellos con foto)');

  /* re-armar _deploy */
  armarDeploy();
}

function armarDeploy() {
  if (!fs.existsSync(DEPLOY)) { console.log('(_deploy no existe, se crea la próxima)'); fs.mkdirSync(DEPLOY, { recursive: true }); }
  fs.rmSync(path.join(DEPLOY, 'assets'), { recursive: true, force: true });
  fs.mkdirSync(path.join(DEPLOY, 'assets', 'fonts'), { recursive: true });
  /* fuentes: solo las que el index realmente usa */
  const html = fs.readFileSync(path.join(ROOT, 'index.html'), 'utf8');
  const usadas = new Set([...html.matchAll(/assets\/fonts\/([^\s'")]+)/g)].map(m => m[1]));
  const A = path.join(ROOT, 'assets');
  let nFiles = 0, bytes = 0;
  const walk = dir => {
    for (const f of fs.readdirSync(dir, { withFileTypes: true })) {
      const p = path.join(dir, f.name);
      if (f.isDirectory()) { walk(p); continue; }
      const rel = path.relative(A, p).replace(/\\/g, '/');
      const dirEntry = rel.split('/')[0];
      const fname = rel.split('/').pop();
      if (dirEntry === 'fonts' && !usadas.has(fname)) continue;
      const dst = path.join(DEPLOY, 'assets', rel);
      fs.mkdirSync(path.dirname(dst), { recursive: true });
      fs.copyFileSync(p, dst);
      nFiles++; bytes += fs.statSync(dst).size;
    }
  };
  walk(A);
  for (const f of ['index.html', 'cfg.js']) {
    const s = path.join(ROOT, f);
    if (fs.existsSync(s)) { fs.copyFileSync(s, path.join(DEPLOY, f)); }
  }
  console.log('_deploy re-armada: ' + nFiles + ' archivos (' + kb(bytes) + ') — listo para arrastrar a Netlify Drop');
}

main().catch(e => { console.error(e); process.exit(1); });