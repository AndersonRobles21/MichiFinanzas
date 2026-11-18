# MichiFinanzas · Propuesta C «Cálido y distintivo» · Wireframe completo

Prototipo navegable con todas las pantallas de la app: arranque, Inicio, Movimientos, Cuentas, Estadísticas,
Compromisos (Suscripciones, Gastos futuros, Deudas y préstamos, Créditos de compra), Ahorros y préstamos y
Configuración, con sus hojas, diálogos y estados. Tema claro, oscuro y comparación lado a lado.

## Abrirlo

Doble clic en `index.html`. Funciona sin internet; solo las fuentes Inter y Nunito vienen de Google Fonts
(sin conexión se ven con la fuente del sistema). Los datos son de ejemplo y nada se guarda.

En el panel izquierdo están los atajos a cada pantalla y hoja. Arriba se cambia entre claro, oscuro y comparar,
con datos o sin datos, y los estados normal, cargando y error. Al final de la página están las especificaciones.

## Carpetas

- `fuente/`: código editable.
  - `plantilla.html`: estilos y estructura de la página.
  - `app.js`: datos de ejemplo, componentes y pantallas (React).
  - `mod4b.js` y `sheets4b.js`: Ahorros y préstamos, Configuración y sus hojas.
  - `react-bundle.js`: React 19 empaquetado (generado con esbuild desde `vendor-entry.js`).
  - `htm-lite.js`: plantillas tipo JSX sin compilador.
  - `cats.js`: las 8 ilustraciones originales de los gatos, en WebP.
  - `build.py`: vuelve a generar `index.html` después de editar: `python fuente/build.py`
- `pruebas/`: pruebas con Playwright (182 verificaciones). Requieren Node y Playwright
  (`npm i playwright` y `npx playwright install chromium`). Se corren desde esa carpeta:
  `node t.js`, `node o.js`, `node c.js`, `node b4.js`, `node crawl.js`.
