# Feature Specification: Sistema de Diseño Loopi v2

**Feature Branch**: `feature/000-design-system`

**Created**: 2026-05-27

**Status**: Draft

**Input**: User description: "Adoptar los estilos de loopi v1: paleta café, fuente Inter, 4 utilidades de componentes (btn-primary, btn-secondary, input-field, card) y optimizaciones móviles"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Identidad Visual Consistente (Priority: P1)

Un desarrollador que construye cualquier vista de Loopi v2 necesita
usar tokens de color, tipografía y componentes base que sean
consistentes con la identidad de marca Loopi (tono café, cálido,
profesional) sin depender de decisiones ad-hoc por vista.

**Why this priority**: Sin una base visual unificada, cada pantalla
nueva generará inconsistencias que degradan la experiencia del
usuario y multiplican el tiempo de diseño y corrección.

**Independent Test**: Se puede testear de forma independiente
construyendo la pantalla de login usando únicamente las clases del
design system y verificando que refleja la identidad de marca sin
CSS adicional.

**Acceptance Scenarios**:

1. **Given** un desarrollador crea una vista nueva, **When** aplica
   las clases `btn-primary`, `btn-secondary`, `input-field` y
   `card`, **Then** la vista tiene la paleta café, tipografía Inter
   y dimensiones definidas sin escribir CSS adicional.
2. **Given** la pantalla de login existe, **When** un usuario la
   abre en móvil (320 px) y en escritorio (1280 px), **Then** los
   colores, tipografía y espaciados son idénticos a la guía de
   diseño en ambos tamaños.

---

### User Story 2 - Accesibilidad en Componentes Base (Priority: P2)

Un usuario con discapacidad visual o que navega por teclado debe
poder interactuar con todos los componentes base (botones, campos,
tarjetas) sin barreras.

**Why this priority**: El cumplimiento WCAG 2.1 AA es un requisito
de la constitución y protege la inclusión digital de los usuarios
de tiendas que operan con Loopi.

**Independent Test**: Se puede testear de forma independiente
verificando contraste de color en botones y campos usando una
herramienta de auditoría de accesibilidad, sin necesidad de que
el resto de la aplicación esté implementado.

**Acceptance Scenarios**:

1. **Given** un componente `btn-primary` renderizado, **When** se
   ejecuta una auditoría de contraste WCAG 2.1 AA, **Then** la
   relación de contraste entre texto y fondo es ≥ 4.5:1.
2. **Given** un formulario con `input-field`, **When** el usuario
   navega con teclado (Tab), **Then** cada campo muestra un estado
   de foco visible y el orden de tabulación es lógico.
3. **Given** cualquier componente base, **When** el campo está en
   estado de error, **Then** el mensaje de error es visible en
   texto (no solo color) junto al campo.

---

### User Story 3 - Experiencia Móvil Fluida (Priority: P2)

Un barista o líder de tienda que usa Loopi en su teléfono móvil
debe poder interactuar con formularios y botones con la misma
facilidad que en escritorio, sin pellizcar ni hacer zoom.

**Why this priority**: El uso operacional de Loopi (inventario,
caja, pedidos) ocurre principalmente en dispositivos móviles en
el piso de la tienda.

**Independent Test**: Se puede testear abriendo la pantalla de
login en un dispositivo de 360 px de ancho y verificando que
todos los elementos son interactuables con el dedo sin
desplazamiento horizontal.

**Acceptance Scenarios**:

1. **Given** cualquier vista que use el design system, **When** se
   carga en un dispositivo de 320 px, **Then** no aparece scroll
   horizontal y todos los elementos son accesibles sin zoom.
2. **Given** un botón `btn-primary` en móvil, **When** el usuario
   intenta pulsarlo, **Then** el área táctil es ≥ 44 × 44 px
   según las pautas de accesibilidad móvil.

---

### User Story 4 - Estados de Interacción Predecibles (Priority: P3)

Un usuario que interactúa con la interfaz debe recibir retroalimentación
visual clara en cada acción: hover, foco, carga, error y éxito.

**Why this priority**: Los estados de interacción evitan que el
usuario repita acciones por falta de confirmación visual, lo que
reduce errores operacionales.

**Independent Test**: Se puede testear de forma independiente en
un componente de botón aislado, verificando que exhibe estados
distintos para normal, hover, foco, deshabilitado y carga.

**Acceptance Scenarios**:

1. **Given** un `btn-primary` habilitado, **When** el usuario hace
   hover, **Then** el botón cambia visualmente (oscurece o añade
   sombra) en ≤ 150 ms.
2. **Given** una acción en progreso, **When** el botón está en
   estado de carga, **Then** está deshabilitado y muestra un
   indicador de actividad.
3. **Given** un `input-field` con valor inválido, **When** el
   usuario sale del campo (blur), **Then** el campo muestra borde
   de error y mensaje de texto descriptivo debajo.

---

### Edge Cases

- ¿Qué ocurre si el sistema operativo del dispositivo tiene modo
  oscuro activado? La v1 no contempla dark mode; se asume que la
  v2 tampoco lo requiere en esta iteración.
- ¿Cómo se comportan los componentes si el navegador bloquea la
  carga de la fuente Inter? Se define una cadena de fuentes de
  respaldo (system-ui, sans-serif) para garantizar legibilidad.
- ¿Qué pasa si se necesita un componente que no está en el design
  system? Se construye con las primitivas de Tailwind siguiendo la
  paleta y tipografía definidas, y se propone su inclusión en el
  design system si es reutilizable.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: El sistema de diseño DEBE proveer una paleta de colores
  de marca basada en tonos café-cálido, definida como tokens (variables
  CSS) reutilizables en toda la aplicación.
- **FR-002**: El sistema de diseño DEBE incluir la fuente Inter como
  tipografía principal, con una cadena de respaldo (system-ui, sans-serif)
  cuando no esté disponible.
- **FR-003**: El sistema de diseño DEBE proveer la clase utilitaria
  `btn-primary` para la acción principal de cada vista: color de fondo
  de marca, texto blanco, estados hover/foco/deshabilitado/carga.
- **FR-004**: El sistema de diseño DEBE proveer la clase utilitaria
  `btn-secondary` para acciones secundarias: apariencia de contorno o
  relleno suave, coherente con la paleta.
- **FR-005**: El sistema de diseño DEBE proveer la clase utilitaria
  `input-field` para campos de formulario: borde sutil, padding
  táctil adecuado, estados normal/foco/error/deshabilitado.
- **FR-006**: El sistema de diseño DEBE proveer la clase utilitaria
  `card` para contenedores de información: fondo blanco, borde suave,
  sombra leve, radio de esquinas consistente.
- **FR-007**: Todos los componentes DEBEN cumplir la relación de
  contraste WCAG 2.1 AA (≥ 4.5:1 para texto normal, ≥ 3:1 para
  texto grande e iconos funcionales).
- **FR-008**: Los componentes DEBEN tener área táctil mínima de
  44 × 44 px en móvil.
- **FR-009**: Los estilos base globales DEBEN establecer: fondo de
  aplicación, color de texto, antialiasing y comportamiento de scroll.
- **FR-010**: El design system DEBE funcionar mobile-first: los estilos
  base son para pantallas ≥ 320 px y se adaptan hacia arriba.

### Key Entities

- **Token de Color**: Variable CSS reutilizable que representa un valor
  de la paleta de marca (ej. color primario, café claro, café oscuro,
  neutros). Cada token tiene un nombre semántico que describe su uso.
- **Utilidad de Componente**: Clase CSS de alto nivel que encapsula la
  apariencia y los estados interactivos de un elemento de interfaz
  (botón, campo, tarjeta). Se aplica directamente en el HTML/template.
- **Token de Tipografía**: Variable CSS que define la familia, tamaño
  y peso de fuente para uso consistente en títulos, cuerpo y etiquetas.
- **Estado de Interacción**: Representación visual de una condición
  del componente (normal, hover, foco, deshabilitado, error, carga).

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Un desarrollador puede construir una vista completa
  nueva usando únicamente las utilidades del design system en menos
  de 30 minutos, sin escribir CSS personalizado.
- **SC-002**: El 100% de los componentes base pasa auditoría WCAG
  2.1 AA de contraste de color (herramienta automatizada).
- **SC-003**: Todas las vistas construidas con el design system se
  renderizan correctamente en pantallas de 320 px sin scroll
  horizontal.
- **SC-004**: Cada componente base exhibe los 5 estados de
  interacción (normal, hover, foco, deshabilitado, error/carga)
  verificables visualmente.
- **SC-005**: La fuente Inter carga en menos de 1 segundo en
  conexión estándar; en caso de fallo, la fuente de respaldo
  mantiene la legibilidad sin saltos de diseño (CLS = 0).
- **SC-006**: El tiempo de carga inicial de estilos no supera 50 KB
  en la hoja de estilos compilada.

## Assumptions

- Se adopta como referencia la paleta y componentes de Loopi v1
  (`--color-primary-*`, `--color-coffee-*`) sin cambios estructurales,
  ajustando únicamente lo necesario para Tailwind CSS v4.
- El design system v2 NO incluye dark mode en esta iteración;
  queda registrado como decisión diferida.
- Los componentes se implementan como clases utilitarias de Tailwind
  (via `@utility` o `@layer components`) en el archivo de estilos
  global, no como Web Components ni librerías externas.
- La fuente Inter se carga desde Google Fonts o se sirve localmente;
  la decisión de hosting se toma durante la implementación.
- Las especificaciones exactas de cada token de color (valores hex)
  se derivan de la paleta documentada en loopi v1 durante la fase
  de planificación.
- Este design system es la base para todas las specs de UI a partir
  de la `001-autenticacion`; cualquier vista ya implementada debe
  migrarse como parte de esta spec.

## Diseño de Interfaz (UX/UI)

### Paleta de Colores

La paleta se basa en tonos café-cálido de Loopi v1. Los tokens CSS
siguen la escala semántica:

| Token semántico | Descripción de uso |
|---|---|
| `--color-primary` | Color de marca principal (café intenso) |
| `--color-primary-hover` | Estado hover del primario |
| `--color-primary-light` | Fondo claro para áreas de énfasis suave |
| `--color-coffee-*` | Escala de grises cálidos (café claro a oscuro) |
| `--color-surface` | Fondo de tarjetas y paneles |
| `--color-error` | Estado de error en formularios |
| `--color-success` | Confirmación de acciones exitosas |

### Tipografía

- **Fuente principal**: Inter (Google Fonts o local)
- **Escala**: headings h1–h4, body, label, caption — definidos
  como tokens de tamaño en la configuración de Tailwind
- **Peso**: Regular (400) para cuerpo, Medium (500) para labels,
  Semibold (600) para headings y botones

### Componentes Base

| Componente | Clase | Descripción |
|---|---|---|
| Botón primario | `btn-primary` | Acción principal; fondo primario, texto blanco |
| Botón secundario | `btn-secondary` | Acción secundaria; contorno primario |
| Campo de formulario | `input-field` | Input y textarea; borde suave, padding táctil |
| Tarjeta | `card` | Contenedor de información; fondo blanco, sombra leve |

### Responsive

- Mobile-first: breakpoints estándar Tailwind (`sm`: 640 px,
  `md`: 768 px, `lg`: 1024 px)
- Mínimo soportado: 320 px de ancho
- Sin scroll horizontal en ningún breakpoint

### Accesibilidad

- Contraste WCAG 2.1 AA en todos los componentes
- Navegación por teclado: Tab order lógico, estados de foco visibles
- Errores de campo: texto descriptivo (no solo color)
- Área táctil móvil: ≥ 44 × 44 px

## Clarifications

### Session 2026-05-27

- Q: ¿Debe el design system incluir dark mode? → A: No en esta iteración; queda como decisión diferida.
- Q: ¿Los componentes se implementan como utilidades Tailwind o como librerías de componentes? → A: Utilidades Tailwind en hoja de estilos global (`@utility`/`@layer components`).
- Q: ¿La fuente Inter se carga desde CDN o se sirve localmente? → A: Se decide en la fase de planificación según las restricciones de rendimiento y privacidad.
