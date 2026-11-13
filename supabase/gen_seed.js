/* Genera 0002_seed.sql desde los snapshots reales del Ente + el catálogo del prototipo.
   Uso: node gen_seed.js   (desde juego/supabase/) */
const fs = require('fs');
const path = require('path');

const RUTA_ROOT = path.resolve(__dirname, '..');
const html = fs.readFileSync(path.join(RUTA_ROOT, 'prototipo', 'index.html'), 'utf8');

const q = v => {
  if (v == null || v === '' || v === 'null') return 'NULL';
  return `'${String(v).replace(/'/g, "''").replace(/\\/g, '\\\\').replace(/\r?\n/g, ' ')}'`;
};
const n = v => (v == null || v === '' || v === 'null' || isNaN(Number(v))) ? 'NULL' : Number(v);

/* ---- SELLOS: parsear las líneas S(...) del prototipo ---- */
const sellos = [];
const reS = /S\('([^']+)','([^']*)','([A-E])','(\w+)','((?:[^']|\\')*)'(?:,(-?[0-9.]+),(-?[0-9.]+))?/g;
for (const m of html.matchAll(reS)) {
  const [, id, nom, cir, tipo, curio, lat, lng] = m;
  sellos.push([id, nom, cir, tipo, curio, lat ? Number(lat) : null, lng ? Number(lng) : null]);
}

/* N1 (nocturno) + P1–P4 (rutas) */
const extrasSellos = [
  ['N1', 'Dormiste en Tucumán', null, 'nocturno', 'Sello nocturno: 1 check-in por pernocte, 1 cada 24 h, x2 puntos en la escalera.', null, null],
  ['P1', 'La voz de Tucumán', 'P', 'ruta', 'Huellas de Mercedes Sosa — 1 check-in en cualquier hito adherido.', null, null],
  ['P2', 'El cosechero que cantó', 'P', 'ruta', 'Huellas de Atahualpa Yupanqui — check-in al final del paseo de Raco.', null, null],
  ['P3', 'El camino de los templos', 'P', 'ruta', 'Ruta de la Fe — 1 check-in en cualquier templo adherido.', null, null],
  ['P4', 'Huellas jesuíticas', 'P', 'ruta', 'Camino Internacional de los Jesuitas — 1 check-in en capillas/estancias.', null, null],
];

const nodos = [
  ['P1', 'A2'], ['P1', 'E4'], ['P2', 'B9'], ['P3', 'D3'], ['P3', 'D4'], ['P4', 'C5'], ['P4', 'E2'],
];

/* ---- PRESTADORES: del snapshot de la API ---- */
const prest = JSON.parse(fs.readFileSync(path.join(RUTA_ROOT, 'prestadores_sitio.json'), 'utf8')).result;

/* ---- Mapping PRESTA del prototipo (id juego → legajo prestador) ---- */
const normKey = s => String(s).toUpperCase().replace(/[^A-Z0-9Ñ]/g, '');
const pKeys = prest.map(r => ({ id: Number(r.id), k: normKey(r.titulo + '-' + (r.legajo || '')) }));
const rePresta = /([A-E]\d+):\[([^\]]+)\]/g;
const reItem = /\{n:'([^']+)',lg:'([^']+)',t:'([^']+)'\}/g;
const mapping = [];   // {sello, items:[{n,lg,t}]}
for (const m of html.matchAll(rePresta)) {
  const items = [...m[2].matchAll(reItem)].map(x => ({ n: x[1], lg: x[2], t: x[3] }));
  mapping.push({ sello: m[1], items });
}

/* ---- ALOJAMIENTOS: del snapshot de la API ---- */
let aloj = JSON.parse(fs.readFileSync(path.join(RUTA_ROOT, 'alojamientos_sitio.json'), 'utf8'));
if (!Array.isArray(aloj) && aloj.result) aloj = aloj.result;

const limpiar = v => (v == null || v === '' || v === 'null' || String(v).trim() === '') ? null : String(v).trim();

/* ---- SQL ---- */
let out = `-- ============================================================================
-- 0002_seed.sql — catálogos y espejos con datos reales del Ente
-- Generado por gen_seed.js el ${new Date().toISOString().slice(0, 10)}.
-- Para refrescar espejos: regenerar este archivo (TRUNCATE de espejos + insert).
-- ============================================================================

begin;

-- espejos primero (sellos/registro referencian alojamientos)
truncate table sello_prestador, alojamiento, prestador restart identity cascade;

insert into prestador (ett_id, nombre, legajo, responsable, localidad_nombre, id_localidad, telefono, email, web, instagram, facebook, actividades, activo)
values
  ${(() => prest.map(r => {
    let nom = r.titulo ? r.titulo.replace(/\s+/g, ' ').replace(/[\s–-]*TA\s*-?\d[\d\s-]*[PD].*$/i, '').trim() : r.titulo;
    nom = (nom || '').replace(/[-–\s]+$/, '');
    const filas = [
      Number(r.id), q(nom), q(String(r.legajo || '').replace(/\s|-| /g, '')), q(r.responsable),
      q(r.localidad_nombre), n(r.idLocalidad), q(r.telefono_final), q(r.email && r.email.trim()),
      q(r.web && r.web !== 'facebook.com' ? r.web.trim() : null),
      q(r.instagram && r.instagram !== 'facebook.com' ? r.instagram : null), q(r.facebook),
      r.nombres_actividades ? `array[${r.nombres_actividades.split(', ').filter(Boolean).map(a => q(a)).join(', ')}]` : "'{}'",
      r.activo === '1',
    ];
    return `(${filas.join(', ')})`;
  }).join(',\n  '))()};

insert into alojamiento (ett_id, nombre, categoria, domicilio, localidad_nombre, id_localidad, lat, lon, telefono, email, web, servicios, activo)
values
  ${aloj.map(r => {
    const est = limpiar(r.estrellas);
    const cat = est ? `${est}★` : limpiar(r.categoria);
    return `(${Number(r.id)}, ${q(r.nombre)}, ${q(cat)}, ${q(r.domicilio)}, ${q(r.localidad)}, ${n(r.idlocalidad)}, ${n(r.latitud)}, ${n(r.longitud)}, ${q(r.telefono_final)}, ${q(r.email)}, ${q(r.web)}, ${q(r.servicios && String(r.servicios).slice(0, 300))}, true)`;
  }).join(',\n  ')};

-- catálogo de sellos
truncate table sello_nodo restart identity cascade;
delete from sello;
insert into sello (id, nombre, circuito, tipo, descripcion, lat, lon) values
  ${sellos.map(([id, nom, cir, tipo, curio, lat, lng]) =>
    `(${q(id)}, ${q(nom)}, ${q(cir)}, ${q(tipo)}, ${q(curio)}, ${n(lat)}, ${n(lng)})`).join(',\n  ')},
  ${extrasSellos.map(([id, nom, cir, tipo, curio, lat, lng]) =>
    `(${q(id)}, ${q(nom)}, ${cir === null ? 'NULL' : q(cir)}, ${q(tipo)}, ${q(curio)}, NULL, NULL)`).join(',\n  ')};

insert into sello_nodo (ruta, nodo) values
  ${nodos.map(([r, nd]) => `(${q(r)}, ${q(nd)})`).join(',\n  ')};

-- sello → prestador recomendado (del PRESTA del prototipo, resuelto por legajo)
${ (() => {
  const filas = [];
  for (const m of mapping) {
    m.items.forEach((it, i) => {
      const k = normKey(it.lg);
      let p = prest.find(r => normKey(r.titulo + '-' + (r.legajo || '')).includes(k));
      if (!p) p = (() => { const f = prest.find(r => normKey(r.titulo).includes(normKey(it.n))); if (f) console.error('⚠ por nombre, no legajo:', it.n); return f; })();
      if (p) filas.push(`(${q(m.sello)}, ${Number(p.id)}, ${i + 1})`);
      else console.error('⚠ no resuelto:', it.n, it.lg);
    });
  }
  return `insert into sello_prestador (sello_id, prestador_id, orden) values
  ${filas.join(',\n  ')};`;
})() }

commit;
`;

fs.writeFileSync(path.join(__dirname, '0002_seed.sql'), out);
console.log('OK: 0002_seed.sql generado');
console.log('sellos:', sellos.length, '| extras:', extrasSellos.length, '| prestadores:', prest.length, '| alojamientos:', aloj.length, '| mapeos sello→prestador:', mapping.reduce((a, m) => a + m.items.length, 0));