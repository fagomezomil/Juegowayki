# El Juego del Verano (Juegowayki)

Webapp del juego turístico de la campaña **"Tucumán, Verano 2027"** (Ente Tucumán Turismo).
Con Wayki como mascotón, el jugador recorre los circuitos de la provincia coleccionando
sellos, armando itinerarios y descubriendo los sabores, alojamientos y prestadores de
cada destino.

## Qué incluye

- **Mapa por circuitos** — Calchaquí, Choromoro, Ciudad, Este, Sur y Yungas, con sus POIs.
- **Sellos coleccionables** — se desbloquean al visitar POIs (por QR) y completan circuitos y rutas transversales (Queso y Vino, Azúcar, Fe, etc.).
- **Itinerarios "5 Sabores"** — recorridos temáticos con fichas, galerías y folletos oficiales en PDF.
- **Directorio turístico** — alojamientos, guías, prestadores de turismo activo y agencias, con contacto y ubicación.
- **Assets propios** — fotos, portadas de circuitos, folletos y la familia de fuentes (Gobold + Sofia Sans).

## Stack

- Vanilla JS / HTML / CSS — sin frameworks.
- Supabase: Postgres, auth, RPC y RLS (`supabase/migrations/0001_schema.sql`).
- `sharp` para la optimización de fotos originales a webp.

## Setup

1. Crear un proyecto en Supabase y correr en el SQL editor
   `supabase/migrations/0001_schema.sql` y `supabase/0002_seed_demo.sql`.
2. Copiar `supabase/.env.example` a `supabase/.env` y completar `SUPABASE_URL` y `SUPABASE_ANON_KEY`.
3. Generar la config del cliente (las credenciales no se suben nunca al repo):

```
cd supabase
node gen_cfg.js
```

4. Abrir `prototipo/index.html` o servir la carpeta con cualquier static server.

### Regenerar fotos

`prototipo/optimizar-fotos.cjs` regenera `assets/fotos/` desde originales en alta:

```
cd prototipo
npm install
node optimizar-fotos.cjs
```

## Estructura

```
prototipo/
  index.html            # el webapp completo
  cfg.js                # config cliente (generada, no commiteada)
  assets/               # fotos, folletos, logos, fuentes, Wayki
  optimizar-fotos.cjs   # pipeline de fotos (sharp)
supabase/
  migrations/0001_schema.sql  # schema: tablas, RPC, policies
  0002_seed_demo.sql     # seed de prueba (sellos reales + prestadores/alojamientos ficticios)
  gen_cfg.js             # genera prototipo/cfg.js desde .env
  gen_seed.js            # genera el seed real (0002_seed.sql, no commiteado: datos de terceros)
```
