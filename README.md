# El Juego del Verano

Web del juego turístico de la campaña "Tucumán, Verano 2027" (Ente Tucumán Turismo):
mapa/recorrido por los circuitos de la provincia con sellos, itinerarios y alojamientos.

## Estructura

- `prototipo/` — el webapp (HTML/CSS/JS vanilla + assets: fotos, folletos, fuentes, Wayki).
- `supabase/` — backend en Supabase.
  - `migrations/0001_schema.sql` — schema (tablas, RPC, policies).
  - `0002_seed.sql` — seed de POIs, sellos, alojamientos y prestadores.
  - `gen_cfg.js` — genera `prototipo/cfg.js` a partir de `.env`.

## Setup

1. Crear proyecto en Supabase y correr `supabase/migrations/0001_schema.sql` y `supabase/0002_seed.sql` en el SQL editor.
2. Copiar `supabase/.env.example` a `supabase/.env` y completar `SUPABASE_URL` y `SUPABASE_ANON_KEY`.
3. Generar la config del cliente:

```
cd supabase
node gen_cfg.js
```

4. Abrir `prototipo/index.html` (o servir la carpeta con cualquier static server).

- `prototipo/optimizar-fotos.cjs` — regenera `assets/fotos/` desde `fotos-originales/` (requiere `npm i` primero, usa sharp).
