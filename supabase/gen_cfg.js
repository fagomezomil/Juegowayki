/* Genera prototipo/cfg.js desde supabase/.env (las keys nunca van comentadas en el HTML)
   Uso: node gen_cfg.js  → escribe ../prototipo/cfg.js */
const fs = require('fs');
const path = require('path');
const env = fs.readFileSync(path.join(__dirname, '.env'), 'utf8');
const get = k => (env.match(new RegExp('^' + k + '=(.*)$', 'm')) || [])[1] || '';
const url = get('SUPABASE_URL').trim();
const key = get('SUPABASE_ANON_KEY').trim();
if (!url || !key) { console.error('Faltan SUPABASE_URL / SUPABASE_ANON_KEY en .env'); process.exit(1); }
const out = `/* generado por gen_cfg.js desde .env — no editar a mano */
window.CFG={url:'${url}',key:'${key}'};
`;
fs.writeFileSync(path.join(__dirname, '..', 'prototipo', 'cfg.js'), out);
console.log('OK: prototipo/cfg.js generado');