# Capibara ESP — fork-owned keys for the vessel/POI boarding splash overlay.
# Grid names and VesselInfo descriptions are raw strings in map/prototype YAML;
# SpaceTextDisplaySystem (Capibara divergence) looks up vessel-<slug>-name/-desc,
# where <slug> = the English grid name lowercased with non-alphanumerics collapsed
# to dashes. Description keys are matched with trailing hull digits stripped
# ("Eris PDV3" -> vessel-eris-pdv-desc). Missing key = raw English fallback.
#
# Intentionally untranslated names (proper nouns / dynamic suffixes):
#   Caelestinus Central, TSFN Chengdu, MMC Hokkaido, PDV Jupiter, TSF-CIV "Stellar Blessing",
#   Bahama Mama's, ADS Zenith CK-395,
#   Cargo Depot (gets a letter appended at runtime, key would never match),
#   ship names (carry a per-purchase hull number that a translation would drop).

## Station / POI names

vessel-crazy-casey-s-casino-name = Casino de Casey el Loco
vessel-derelict-mccargo-name = McCargo Abandonado
vessel-grifty-s-gas-n-grub-name = Gasolina y Papeo de Grifty
vessel-the-pit-name = El Pozo
vessel-tinnia-s-rest-name = El Descanso de Tinnia
vessel-anomalous-lab-name = Laboratorio Anómalo
vessel-automated-inter-sector-tanker-name = Cisterna Intersectorial Automatizada
vessel-derelict-drillsite-name = Zona de Perforación Abandonada
vessel-edison-power-plant-name = Central Eléctrica Edison
vessel-freeport-camelot-name = Puerto Libre Camelot
vessel-hammer-of-the-union-name = Martillo de la Unión
vessel-lancelot-mining-outpost-name = Puesto Minero Lancelot
vessel-listening-point-bravo-name = Punto de Escucha Bravo
vessel-medical-dispatch-name = Despacho Médico
vessel-pdv-helio-fortress-name = Fortaleza Helio del PDV
vessel-pdv-jupiter-class-carrier-name = Portanaves Clase Júpiter del PDV
vessel-polaris-bioresearch-center-name = Centro de Bioinvestigación Polaris
vessel-sevastopol-data-storage-center-name = Centro de Almacenamiento de Datos Sevastopol
vessel-trade-mall-name = Centro Comercial
vessel-tsfmc-flagship-halcyon-name = Buque Insignia del TSFMC Halcyon
vessel-tsfmc-secondary-outpost-name = Puesto Secundario del TSFMC
vessel-zvezda-orbital-habitation-name = Hábitat Orbital Zvezda
vessel-zeta-node-name = Nodo Zeta
vessel-inso-357k-asteroid-cluster-name = Cúmulo de Asteroides INSO-357k
vessel-linear-21-asteroid-cluster-name = Cúmulo de Asteroides LINEAR-21
vessel-pdv-helios-fortress-name = Fortaleza Helios del PDV

## Vessel descriptions (VesselInfo)

vessel-caelestinus-central-desc = Lo más parecido a la civilización en este sector. Casi te sientes a salvo.
vessel-pdv-helio-fortress-desc = Un aura imperial opresiva acecha este lugar. Gloria al Sultán.
vessel-pdv-helios-fortress-desc = Un aura imperial opresiva acecha este lugar. Gloria al Sultán.
vessel-tsfmc-flagship-halcyon-desc = Un acorazado retirado convertido en base avanzada, y hogar de las operaciones del TSFMC.
vessel-freeport-camelot-desc = Una vieja estación destartalada, remendada a lo largo de muchísimos ciclos...
vessel-eris-pdv-desc = Construida para ser barata y eficaz, esta nave consigue aun así que varias toneladas de acero se sientan como un puente desvencijado.
vessel-europa-pdv-desc = La nave hermana del Saturn.
vessel-ganymede-pdv-desc = A medio construir, ensamblada a golpes para repeler a la escoria de la TSF...
vessel-garm-pdv-desc = Un viejo casco de carga que ahora monta armamento de bombardeo pesado, capaz de devolver estaciones a la Edad de Piedra.
vessel-kalisto-pdv-desc = Estrecha y sucia. Esto solo puede acabar bien...
vessel-vulture-pdv-desc = Se rumorea que un Vulture arrasó un planeta pequeño él solo. Ahora te toca a ti comprobarlo.
vessel-flyssa-tsfn-desc = El orgullo de la TSFN y una estrella brillante en el sector. Sol invictus.
vessel-saturn-hss-desc = La respuesta del Sultán a los invasores del TSFMC. Aguanta castigo como ningún otro casco. Alabado sea el Sultán.
vessel-altair-tsfn-desc = Una fragata resistente construida para aguantar un castigo brutal... y sobrevivir. Con suerte, los condensadores de refrigerante no reventarán.
vessel-andromeda-tsf-desc = Suficientes cañones para tapar las estrellas.
vessel-buran-ussp-desc = Anticuada, pero aún fiable.
vessel-ledokol-ussp-desc = ¿Por qué habré venido a este sector?
vessel-zvezda-orbital-habitation-desc = Una estación medio abandonada y en descomposición. A veces se oye cómo se dobla el casco.
vessel-tsfn-chengdu-desc = Suficiente armamento pesado para partir un planeta.
vessel-zeta-node-desc = Hasta el aire tiene una fina capa de polvo.
vessel-tsf-civ-stellar-blessing-desc = Una nave colonial del sistema de la Federación, enviada al Radio de Colossus para la expansión industrial. Hogar de civiles de la TSF.
vessel-metis-pdv-desc = Diminuta, estrecha y mal construida. Este casco no durará mucho...
vessel-aldebaran-tsf-desc = Uno de los pilares de la Federación: rápida, precisa y, con suerte, letal.
vessel-hoplite-tsf-desc = Un armazón pequeño pero potente; cuidado con el latigazo de los propulsores.
vessel-shiv-tsf-desc = Una nave tan curtida que aún se ven las cicatrices de la radiación bajo la pintura nueva.
vessel-spica-tsf-desc = Esta nave es la encarnación viva de una patrullera solariana militarizada: va rápido y tiene capacidad EMP suficiente para freír, de forma permanente, todos los sistemas eléctricos de un carguero pequeño.
