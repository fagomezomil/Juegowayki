-- ============================================================================
-- 0002_seed_demo.sql — catálogos con DATOS DE PRUEBA (sin datos reales)
--
-- Para producción/región real se usa `0002_seed.sql`, generado con
-- `node gen_seed.js` a partir de los espejos de la API del Ente. Ese
-- archivo contiene datos reales de terceros y no se commitea.
--
-- Este demo permite levantar y probar el juego completo con prestadores
-- y alojamientos ficticios. El catálogo de sellos es el real del juego.
-- ============================================================================

begin;

truncate table sello_prestador, alojamiento, prestador restart identity cascade;

insert into prestador (ett_id, nombre, legajo, responsable, localidad_nombre, id_localidad, telefono, email, web, instagram, facebook, actividades, activo)
values
  (9001, 'DEMO TREKKING ANDINO', 'TA0001P', 'Pérez, Ana (demo)', 'San Miguel de Tucumán', 1, '+540000000001', 'demo.trekking@ejemplo.com', 'https://www.ejemplo.com/trekking', NULL, NULL, array['Trekking', 'Senderismo'], true),
  (9002, 'DEMO AVENTURA EN EL AIRE', 'TA0002P', 'Gómez, Bruno (demo)', 'San Javier', 46, '+540000000002', 'demo.aventura@ejemplo.com', NULL, 'https://www.instagram.com/ejemplo', NULL, array['Parapente', 'Tirolesa'], true),
  (9003, 'DEMO ECO-SENDAS', 'TA0003P', 'Luna, Carla (demo)', 'El Mollar', 68, '+540000000003', 'demo.ecosendas@ejemplo.com', 'https://www.ejemplo.com/ecosendas', NULL, NULL, array['Senderismo', 'Safari Fotográfico'], true);

insert into alojamiento (ett_id, nombre, categoria, domicilio, localidad_nombre, id_localidad, lat, lon, telefono, email, web, servicios, activo)
values
  (9001, 'HOTEL DEMO CENTRO', '3★', 'San Martín 100 (demo)', 'San Miguel de Tucumán', 1, -26.8300, -65.2030, '+540000000101', 'demo.hotel.centro@ejemplo.com', NULL, 'Desayuno,Wi-Fi', true),
  (9002, 'HOSTERÍA DEMO VALLE', '2★', 'Av. Principal 200 (demo)', 'Tafí del Valle', 51, -26.8530, -65.7060, '+540000000102', 'demo.hosteria.valle@ejemplo.com', NULL, 'Baño privado,Cochera,Desayuno,Piscina,Wi-Fi', true),
  (9003, 'CABAÑAS DEMO SIERRA', '0★', 'Camino a la Sierra 300 (demo)', 'El Mollar', 68, -26.9000, -65.6800, '+540000000103', 'demo.cabanas.sierra@ejemplo.com', NULL, 'Baño privado,Estacionamiento al aire libre', true);

truncate table sello_nodo restart identity cascade;

-- catálogo de sellos
delete from sello;
insert into sello (id, nombre, circuito, tipo, descripcion, lat, lon) values
  ('A1', 'La casa donde nació la patria', 'A', 'lugar', 'Museo Casa Histórica de la Independencia: acá se firmó la Independencia en 1816. -26.83, -65.21', NULL, NULL),
  ('A2', 'Plaza, catedral y basílica', 'A', 'lugar', 'Plaza Independencia, Catedral y Basílica de La Merced: el corazón del casco histórico de SMT.', NULL, NULL),
  ('A3', 'El parque gigante', 'A', 'lugar', 'Parque 9 de Julio, con el Museo de la Industria Azucarera Obispo Colombres (Ruta del Azúcar).', -26.838, -65.208),
  ('A4', 'Los museos que nadie recorre', 'A', 'lugar', 'Casa Padilla, Museo Folklórico Belgrano, Museo Iramain: tres museos a pie, gratis.', NULL, NULL),
  ('A5', 'La patria de noche', 'A', 'noche', '"Luces y Sonidos de la Independencia": jue–dom, de noche, junto a la Casa Histórica.', NULL, NULL),
  ('B1', 'El pueblo del bosque', 'B', 'lugar', 'Villa Nougués: casco de piedra y bosques de montaña a 25 min de la ciudad. -26.80, -65.29', NULL, NULL),
  ('B2', 'El bosque de Percy', 'B', 'lugar', 'Parque Percy Hill, Yerba Buena: yungas, aves y agenda pública activa.', NULL, NULL),
  ('B3', 'El parque de la sierra', 'B', 'lugar', 'Parque Horco Molle (mié–dom): mirador Rondavía, el cristo, el Sendero El Funicular y la Reserva de fauna, abierta al público.', NULL, NULL),
  ('B4', 'El cristo que mira a la ciudad', 'B', 'lugar', 'Complejo Cristo Bendicente, San Javier — el sello REAL del MVP: probá el check-in GPS acá. De noche, "Cristo Resplandeciente". ★ REAL', -26.792, -65.313),
  ('B5', 'Agua, playa y museo', 'B', 'lugar', 'Complejo El Cadillal, Tafí Viejo: playa, kayak, aerosilla y museo arqueológico, a 30 min. ★ REAL — sello 2 del MVP.', -26.681, -65.262),
  ('B6', 'La eco-senda del bosque', 'B', 'sendero', 'Inicios de las eco-sendas de San Javier (El Funicular, Río Noque, Puerta del Cielo, Cuesta Vieja). Con prestador habilitado.', NULL, NULL),
  ('B7', 'El mirador de la voz latinoamericana', 'B', 'lugar', 'Mirador Mercedes Sosa, RP 341: la mejor foto de la ciudad, con la Negra en el paisaje.', NULL, NULL),
  ('B8', 'Aventura en el aire', 'B', 'exp', 'RAKI (96 puentes), parapente en Loma Bola o la tirolesa más larga del país. Con prestador.', NULL, NULL),
  ('B9', 'El pueblo de las brumas', 'B', 'lugar', 'Raco y las Huellas de Yupanqui: paseo de 850 m con sus versos. Nodo del sello P2. Sello de ruta P2.', NULL, NULL),
  ('C1', 'El paso de las nubes', 'C', 'lugar', 'Mirador El Infiernillo a 3.041 m: frío de sierra y venturas del valle.', NULL, NULL),
  ('C2', 'La foto del Indio', 'C', 'lugar', 'Monumento al Indio: la parada clásica en la subida a Tafí.', NULL, NULL),
  ('C12', 'El remanso del dique', 'C', 'lugar', 'Dique La Angostura: aguas mansas, balnearios y kayak, a ~25 km del Monumento.', NULL, NULL),
  ('C3', 'Reserva Río Los Sosa', 'C', 'lugar', 'Cascadas y pozas de la reserva provincial, en la bajada de la RP 307.', NULL, NULL),
  ('C4', 'Herencia ancestral', 'C', 'lugar', 'Parque Arqueológico Los Menhires, El Mollar: monolitos tallados hace siglos (la ficha del wireframe del GDD).', NULL, NULL),
  ('C5', 'Tras el paso de los jesuitas', 'C', 'lugar', 'Museo Jesuítico de La Banda: la etapa jesuítica del valle. También es nodo del P4.', NULL, NULL),
  ('C6', 'El oficio del valle', 'C', 'lugar', 'Ruta del Artesano, Tafí del Valle: telar, cuero y chaguar en los talleres.', -26.583, -65.711),
  ('C7', 'La tierra de la Pachamama', 'C', 'lugar', 'Amaicha del Valle: museos, bodega comunitaria y ceremonias. -26.60, -65.90', NULL, NULL),
  ('C8', 'Vinos de altura', 'C', 'cata', 'Cata en bodega de la Ruta del Vino de Altura (Colalao del Valle: Los Amaichas, Luna de Cuarzo…).', NULL, NULL),
  ('C9', 'La ciudad que nunca se rindió', 'C', 'lugar', 'Ruinas de Quilmes: terrazas y muros de piedra del pueblo diaguita-quilmeño. -26.67, -65.99', NULL, NULL),
  ('C10', 'Recorrido serrano', 'C', 'sendero', 'Senda El Pelao, RP 325 (El Mollar): circular 5 km (~2 h) o 9 km (~3 h), con vistas del valle y del dique. Con prestador.', NULL, NULL),
  ('C13', 'Vertientes del valle', 'C', 'sendero', 'Cascada Los Alisos, El Mollar: 1.8 km (~2 h). Con prestador.', NULL, NULL),
  ('C11', 'El pueblo de piedra', 'C', 'comunitario', 'Talapazo, comunidad Quilmes: pan, frangollo, leyendas, Pachamama y eco-sendas (con reserva previa).', NULL, NULL),
  ('D1', 'El valle de los nogales', 'D', 'lugar', 'Hualinchay, Trancas (18 km oeste de San Pedro, ~1.700 m): cascadas de los ríos Tacanas y Tipas, la piedra arqueológica tallada como mapa de los cuatro puntos cardinales y museo de la Comunidad Indígena Cacique Marcos Pasayo.', NULL, NULL),
  ('D2', 'Refrescá tu paseo', 'D', 'lugar', 'Balnearios sobre los ríos Tacana y Tipa, San Pedro de Colalao: pozas naturales, sombra y camping. El clásico baño de verano del valle.', NULL, NULL),
  ('D3', 'El templo del brigadier', 'D', 'lugar', 'Iglesia Sagrado Corazón, Trancas: acá fue preso y murió Bernabé Aráoz (24/3/1831). Nodo P3.', NULL, NULL),
  ('D4', 'El pozo milagroso', 'D', 'lugar', 'Pozo de San Francisco Solano y sus aguas, en Trancas. Nodo P3.', NULL, NULL),
  ('D5', 'La sendera del monolito', 'D', 'sendero', 'Piedra Tallada: roca de ~4 m con grabados de 2.000 años, sagrada para la Comunidad Indio Colalao. Caminata de 1.30 h desde el centro de San Pedro cruzando el río Tipas, con guía local.', NULL, NULL),
  ('D6', 'La gruta que se enciende', 'D', 'noche', 'Mapping "Lourdes, un mensaje de Amor" sobre la Gruta de Lourdes (Colalao): mié–dom 20.00 y 20.30 h.', NULL, NULL),
  ('D7', 'El museo escondido', 'D', 'lugar', 'Museo García Salemi, calle 24 de Septiembre, Colalao: cerámicas, urnas y petroglifos.', NULL, NULL),
  ('E1', 'Nací en Famaillá', 'E', 'exp', 'Circuito de la Empanada: talleres, horno a leña y la degustación. Sello foto del plato.', NULL, NULL),
  ('E2', 'El templo junto al cementerio', 'E', 'lugar', 'Iglesia Jesuítica San Ignacio de Loyola (La Cocha, 1746–57, MHN). Nodo P3 y P4.', NULL, NULL),
  ('E3', 'Tradición y gastronomía regional', 'E', 'exp', 'Feria de Simoca, solo sábados: carros a sulki, artesanías en caña y feria gastronómica. -27.30, -65.36', NULL, NULL),
  ('E4', 'Tierra de la randa', 'E', 'exp', 'Monteros: Mercado Cultural, Museo de la caña y la randa, tejido patrimonio de Tucumán.', NULL, NULL),
  ('E5', 'El espejo de Escaba', 'E', 'lugar', 'Dique Escaba en kayak + la hostería al agua, en Villa Alberdi (nocturno posible).', NULL, NULL),
  ('E6', 'Túneles bajo la sierra', 'E', 'sendero', 'Eco-senda Túneles de Rumi Punco: cascadas de 15 m y túneles de montaña. Con guía.', NULL, NULL),
  ('E7', 'Los caminos del parque', 'E', 'sendero', 'PN Aconquija: Portales Cochuna y Campo de los Alisos. La joya: La Ciudacita (2 días con prestador).', NULL, NULL),
  ('N1', 'Dormiste en Tucumán', NULL, 'nocturno', 'Sello nocturno: 1 check-in por pernocte, 1 cada 24 h, x2 puntos en la escalera.', NULL, NULL),
  ('P1', 'La voz de Tucumán', 'P', 'ruta', 'Huellas de Mercedes Sosa — 1 check-in en cualquier hito adherido.', NULL, NULL),
  ('P2', 'El cosechero que cantó', 'P', 'ruta', 'Huellas de Atahualpa Yupanqui — check-in al final del paseo de Raco.', NULL, NULL),
  ('P3', 'El camino de los templos', 'P', 'ruta', 'Ruta de la Fe — 1 check-in en cualquier templo adherido.', NULL, NULL),
  ('P4', 'Huellas jesuíticas', 'P', 'ruta', 'Camino Internacional de los Jesuitas — 1 check-in en capillas/estancias.', NULL, NULL);

insert into sello_nodo (ruta, nodo) values
  ('P1', 'A2'),
  ('P1', 'E4'),
  ('P2', 'B9'),
  ('P3', 'D3'),
  ('P3', 'D4'),
  ('P4', 'C5'),
  ('P4', 'E2');

-- sello → prestador recomendado (con los prestadores demo de arriba)
insert into sello_prestador (sello_id, prestador_id, orden) values
  ('B6', 9001, 1),
  ('B8', 9002, 1),
  ('B8', 9003, 2),
  ('C10', 9003, 1),
  ('C13', 9003, 2);

commit;
