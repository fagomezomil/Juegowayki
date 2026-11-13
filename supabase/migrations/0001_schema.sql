-- ============================================================================
-- EL JUEGO DEL VERANO — esquema inicial (Temporada 0)
-- Derivado del GDD §8 (panel/kpis), §7.9 (grupo), §4.2 (registro), §3 (sellos).
-- Convención: tablas en español (legible para el panel del Ente en Metabase).
-- El diseño del juego vive acá; los espejos alojamiento/prestador se
-- sincronizan desde la API del Ente (fuente upstream, ver GDD §2 y
-- Registros guias y prestadores turismo activo.md).
-- ============================================================================

-- ---------------------------------------------------------------------------
-- 1. ESPEJOS DE DATOS DEL ENTE (sincronizados, nunca consumidos en vivo)
-- ---------------------------------------------------------------------------

create table if not exists alojamiento (
  ett_id            integer primary key,                 -- id de la API del Ente
  nombre            text not null,
  categoria         text,                                -- estrellas o tipo (API)
  domicilio         text,
  localidad_nombre  text,
  id_localidad      integer,
  lat               double precision,
  lon               double precision,
  telefono          text,
  email             text,
  web               text,
  servicios         text,
  adherido          boolean not null default false,      -- convenio de premios ⚠ decision Ente
  activo            boolean not null default true,
  sincronizado      timestamptz not null default now(),
  fuente            text not null default 'api-ett/hoteles'
);

create table if not exists prestador (
  ett_id            integer primary key,
  nombre            text not null,                       -- titulo en la API
  legajo            text,                                -- TA-####-P / ####-D
  responsable       text,
  localidad_nombre  text,
  id_localidad      integer,
  telefono          text,
  email             text,
  web               text,
  instagram         text,
  facebook          text,
  actividades       text[] default '{}',                 -- Trekking, Kayak, ...
  adherido          boolean not null default false,
  activo            boolean not null default true,
  sincronizado      timestamptz not null default now(),
  fuente            text not null default 'api-ett/prestadores'
);
create index if not exists idx_prestador_localidad on prestador (localidad_nombre);
create index if not exists idx_prestador_actividades on prestador using gin (actividades);

-- ---------------------------------------------------------------------------
-- 2. CATÁLOGO DE SELLOS (A–E + productos P + nocturno N1)
-- ---------------------------------------------------------------------------

create table if not exists sello (
  id          text primary key,                          -- 'A1'..'E7','P1'..'P4','N1'
  nombre      text not null,
  circuito    text check (circuito in ('A','B','C','D','E','P')),  -- NULL solo para N1 (nocturno)
  tipo        text not null,                             -- lugar|sendero|exp|cata|noche|comunitario|ruta|nocturno
  descripcion text,
  lat         double precision,                          -- validar en campo (GDD §3)
  lon         double precision,
  radio       integer not null default 150,              -- metros; 300 bajo dosel (GDD reglas)
  localidad   text,                                      -- ⚠ completar con base validada
  departamento text,                                     -- ⚠ leer telemetría vs EOH/SEP (§3.0) — a validar
  activo      boolean not null default true
);

-- Productos P1–P4: 1 check-in en cualquier nodo otorga el sello de ruta
create table if not exists sello_nodo (
  ruta  text not null references sello(id) on delete cascade,
  nodo  text not null references sello(id) on delete cascade,
  primary key (ruta, nodo)
);

-- Prestador recomendado por sello (eco-sendas / experiencias con prestador;
-- null → fallback "consultá informes", cobertura despareja del padrón)
create table if not exists sello_prestador (
  sello_id     text not null references sello(id) on delete cascade,
  prestador_id integer not null references prestador(ett_id) on delete cascade,
  orden        smallint not null default 1,              -- 1º/2º recomendado en la ficha
  primary key (sello_id, prestador_id)
);

-- ---------------------------------------------------------------------------
-- 3. REGISTRO (Ley 25.326 — datos para canje y contacto de premiados)
-- ---------------------------------------------------------------------------

create table if not exists registro (
  id           uuid primary key default gen_random_uuid(),
  creado       timestamptz not null default now(),
  dispositivo  text unique,                              -- anti-fraude GDD §4.4
  fuente       text not null default 'web_ett'
               check (fuente in ('qr','redes','web_ett','cartilla','presencial','demo')),
  nombre       text not null,
  apellido     text not null,
  celular      text not null,
  email        text,
  origen       text not null
               check (origen in ('smt','interior','amba','noa','otra_ar','exterior')),
  quien_juega  text check (quien_juega in ('solo','pareja','chicos','amigos')),
  noches       text check (noches in ('1','2-3','4-7','8+','dia')),
  aloj_tipo    text check (aloj_tipo in ('red_ett','parahotel','casa','camping','ns')),
  hotel_id     integer references alojamiento(ett_id),   -- si eligió red ETT
  foto         text,                                     -- path en storage
  optin        boolean not null default false,           -- novedades Ente
  fecha_nac    date,                                     -- opcional (mayor/menor, GDD)
  activo       boolean not null default true
);
create index if not exists idx_registro_creado on registro (creado);
create index if not exists idx_registro_origen on registro (origen);

-- ---------------------------------------------------------------------------
-- 4. GRUPO (§7.9: union de sellos, cap 6, codigo 5 letras)
-- ---------------------------------------------------------------------------

create table if not exists grupo (
  id         uuid primary key default gen_random_uuid(),
  codigo     text not null unique,                       -- 5 letras A–Z
  nombre     text not null,                              -- "Los Ruiz por el verano"
  creado_por uuid references registro(id),
  creado     timestamptz not null default now(),
  activo     boolean not null default true
);

create table if not exists grupo_miembro (
  registro_id uuid primary key references registro(id) on delete cascade,  -- 1 grupo por persona
  grupo_id    uuid not null references grupo(id) on delete cascade,
  unido       timestamptz not null default now()
);
create index if not exists idx_grupo_miembro_grupo on grupo_miembro (grupo_id);

-- ---------------------------------------------------------------------------
-- 5. CHECK-INS Y SELLOS NOCTURNOS (N1 = 1 cada 24 h, GDD §4.4)
-- ---------------------------------------------------------------------------

create table if not exists checkin (
  id          bigint generated always as identity primary key,
  creado      timestamptz not null default now(),
  registro_id uuid not null references registro(id),
  sello_id    text not null references sello(id),
  medio       text not null check (medio in ('gps','qr','hotel','codigo','simulado')),
  lat         double precision,                          -- posición del dispositivo
  lon         double precision,
  hotel_id    integer references alojamiento(ett_id),    -- N1: dónde pernoctó
  dispositivo text,
  valido      boolean not null default true,             -- anti-fraude puede anular
  nota        jsonb                                      -- {distancia_m, velocidad, ...}
);
create unique index if not exists uq_checkin_sello
  on checkin (registro_id, sello_id) where sello_id <> 'N1';
create index if not exists idx_checkin_reg on checkin (registro_id);
create index if not exists idx_checkin_sello on checkin (sello_id, creado);
create index if not exists idx_checkin_creado on checkin (creado);

-- ---------------------------------------------------------------------------
-- 6. PREMIOS (escalera 3/5/7/12/20/26 individual + 10/20 grupo; §4.2 y §7.9)
-- ---------------------------------------------------------------------------

create table if not exists premio_claim (
  id          bigint generated always as identity primary key,
  creado      timestamptz not null default now(),
  registro_id uuid not null references registro(id),
  grupo_id    uuid references grupo(id) on delete cascade,
  alcance     text not null,                             -- companiero|amigo|hermano|grupo_10|grupo_20
  nivel       integer not null,                          -- sellos exigidos al emitir
  codigo      text not null unique,                      -- WJ-XXXX
  estado      text not null default 'emitido'
              check (estado in ('emitido','canjeado','vencido','anulado')),
  canjeado    timestamptz,
  oficina     text                                       -- 17 oficinas (Contactos oficinas...)
);
create index if not exists idx_premio_reg on premio_claim (registro_id);
create index if not exists idx_premio_estado on premio_claim (estado, creado);

-- ---------------------------------------------------------------------------
-- 7. YAPA (compartir sello en IG; tope 3/temporada, §5.4)
-- ---------------------------------------------------------------------------

create table if not exists yapa (
  id          bigint generated always as identity primary key,
  creado      timestamptz not null default now(),
  registro_id uuid not null references registro(id) on delete cascade,
  sello_id    text not null references sello(id),
  unique (registro_id, sello_id)                         -- 1 yapa por sello
);

-- ---------------------------------------------------------------------------
-- 8. FRESCO CHALLENGE (§5: reto semanal sábados 10 h dic–feb)
-- ---------------------------------------------------------------------------

create table if not exists reto (
  id     bigint generated always as identity primary key,
  fecha  date not null,
  titulo text not null,
  activo boolean not null default true
);

create table if not exists reto_upload (
  id          bigint generated always as identity primary key,
  creado      timestamptz not null default now(),
  registro_id uuid not null references registro(id) on delete cascade,
  reto_id     bigint not null references reto(id),
  foto        text not null,                             -- path en storage
  derechos    boolean not null default false,            -- checkbox de repost
  estado      text not null default 'pendiente'
              check (estado in ('pendiente','aprobado','rechazado')),
  motivo      text,                                      -- si rechaza (SLA 72 h, §8.2)
  unique (registro_id, reto_id)
);

-- ---------------------------------------------------------------------------
-- 9. JARDÍN DE WAYKI (§6: árboles por familia/grupo + cartilla J3)
-- ---------------------------------------------------------------------------

create table if not exists jardin (
  id          bigint generated always as identity primary key,
  dueno_solo  uuid references registro(id) on delete cascade,   -- familia
  dueno_grupo uuid references grupo(id)   on delete cascade,    -- jardín grupal (7.9.5)
  arboles     integer not null default 0,
  especies    jsonb not null default '{}'            -- {eucalipto: 3, laurel: 1, ...}
);
create unique index if not exists uq_jardin_solo on jardin (dueno_solo) where dueno_solo is not null;
create unique index if not exists uq_jardin_grupo on jardin (dueno_grupo) where dueno_grupo is not null;

create table if not exists cartilla (
  codigo      text primary key,                          -- código impreso por lote (QR único)
  lote        text not null,
  canjeada_por uuid references registro(id),
  canjeada    timestamptz,
  eco_senda   text references sello(id)                  -- la eco-senda real del J3
);

-- ---------------------------------------------------------------------------
-- 10. TELEMETRÍA (sin GA en el sitio oficial: acá cae todo, §4.3 / §8)
-- ---------------------------------------------------------------------------

create table if not exists evento (
  id          bigint generated always as identity primary key,
  creado      timestamptz not null default now(),
  registro_id uuid references registro(id),
  dispositivo text,
  tipo        text not null,                             -- onboarding_start, ficha_abierta, share, ...
  datos       jsonb,
  fuente      text                                       -- fuente de la sesión (adquisición)
);
create index if not exists idx_evento_tipo on evento (tipo, creado);

-- ---------------------------------------------------------------------------
-- 11. STORAGE: bucket público para fotos (usuario/grupo/sellos/uploads)
-- ---------------------------------------------------------------------------

insert into storage.buckets (id, name, public) values ('fotos', 'fotos', true)
  on conflict (id) do nothing;
create policy "fotos publico leido" on storage.objects
  for select using (bucket_id = 'fotos');
create policy "fotos publico sube" on storage.objects
  for insert to anon with check (bucket_id = 'fotos');

-- ---------------------------------------------------------------------------
-- 12. RLS (MVP Temporada 0: escritura anónima controlada + lectura de espejos)
--     ⚠ EN PRODUCCIÓN: auth de Supabase y policies por dueño; los datos
--     personales no se leen anónimamente (Ley 25.326).
-- ---------------------------------------------------------------------------

alter table alojamiento      enable row level security;
alter table prestador        enable row level security;
alter table sello            enable row level security;
alter table sello_nodo       enable row level security;
alter table sello_prestador  enable row level security;
alter table grupo            enable row level security;
alter table grupo_miembro    enable row level security;
alter table registro         enable row level security;
alter table checkin          enable row level security;
alter table premio_claim     enable row level security;
alter table yapa             enable row level security;
alter table reto             enable row level security;
alter table reto_upload      enable row level security;
alter table jardin           enable row level security;
alter table cartilla         enable row level security;
alter table evento           enable row level security;

-- Lectura pública: catálogos y espejos (el juego los sirve al diario)
create policy "lectura alojamiento"  on alojamiento     for select to anon using (true);
create policy "lectura prestador"    on prestador       for select to anon using (true);
create policy "lectura sello"        on sello           for select to anon using (true);
create policy "lectura sello_nodo"   on sello_nodo      for select to anon using (true);
create policy "lectura sello_prest"  on sello_prestador for select to anon using (true);
create policy "lectura reto"         on reto            for select to anon using (true);

-- Escritura anónima por el cliente (MVP: sin auth; ⚠ producción = auth)
create policy "alta registro"       on registro     for insert to anon with check (true);
create policy "edita registro MVP"  on registro     for update to anon using (true) with check (true);  -- ⚠ Temporada 0: con auth, solo el dueño
create policy "alta grupo"          on grupo        for insert to anon with check (true);
create policy "lectura grupo"       on grupo        for select to anon using (true);
create policy "alta miembro grupo"  on grupo_miembro for insert to anon with check (true);
create policy "lectura miembro"     on grupo_miembro for select to anon using (true);
create policy "alta checkin"        on checkin      for insert to anon with check (true);
create policy "alta premio"         on premio_claim for insert to anon with check (true);
create policy "alta yapa"           on yapa         for insert to anon with check (true);
create policy "alta reto up"        on reto_upload  for insert to anon with check (true);
create policy "alta jardin"         on jardin       for insert to anon with check (true);
create policy "alta evento"         on evento       for insert to anon with check (true);
-- cartilla: solo el panel (security definer) la marca canjeada — sin policy anónima

-- ---------------------------------------------------------------------------
-- 13. VISTAS KPI para Metabase (§8.1)
-- ---------------------------------------------------------------------------

create or replace view v_pernocte_localidad as
  select a.localidad_nombre, date_trunc('month', c.creado) as mes, count(*) as nocturnos
  from checkin c join alojamiento a on a.ett_id = c.hotel_id
  where c.sello_id = 'N1' and c.valido
  group by 1, 2 order by 2, 1;

create or replace view v_checkins_circuito as
  select s.circuito, s.departamento, date_trunc('week', c.creado) as semana, count(*) as checkins
  from checkin c join sello s on s.id = c.sello_id
  where c.valido
  group by 1, 2, 3 order by 3;

create or replace view v_adquisicion as
  select fuente, date_trunc('week', creado) as semana, count(*) as registros
  from registro group by 1, 2 order by 2;