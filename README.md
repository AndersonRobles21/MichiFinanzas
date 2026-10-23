# MichiFinanzas

### Organiza tu dinero de una forma sencilla, visual y práctica

MichiFinanzas es una aplicación de finanzas personales desarrollada con Flutter y Dart, diseñada para ayudar a las personas a organizar sus ingresos, controlar sus gastos, administrar sus deudas y conocer mejor el estado de sus finanzas.

La aplicación cuenta con una interfaz visual basada en tonos morados e ilustraciones de gatos, buscando que el manejo del dinero sea una experiencia más agradable, intuitiva y fácil de entender.

Su objetivo es ofrecer una herramienta práctica para llevar el control financiero desde el celular, sin necesidad de utilizar hojas de cálculo o registrar cada movimiento manualmente en documentos separados.

---

##  Características principales

MichiFinanzas reúne diferentes herramientas para administrar las finanzas personales desde una sola aplicación.

- **Registro de ingresos:** permite repartir cada ingreso entre efectivo y una o varias cuentas digitales; no se guarda hasta que la suma coincida con el valor recibido.
- **Cuentas y saldos:** organiza el saldo entre efectivo y cuentas digitales personalizadas, con movimientos asociados a cada cuenta.
- **Transferencias internas:** mueve dinero entre medios o cuentas sin contarlo dos veces como ingreso o gasto.
- **Control de gastos:** permite registrar los gastos realizados, clasificarlos por categoría y editar los registros cuando sea necesario.
- **Administración de deudas:** facilita el seguimiento de obligaciones económicas, cuotas, abonos y saldos pendientes.
- **Gastos futuros:** permite organizar gastos previstos y confirmar o cancelar las reservas de dinero correspondientes.
- **Estadísticas financieras:** presenta información visual para comprender cómo se distribuyen los gastos y cómo se utiliza el dinero.
- **Seguimiento del ahorro:** ofrece herramientas para visualizar y organizar el dinero disponible para ahorrar.
- **Suscripciones:** administra servicios recurrentes y permite confirmar pagos reales. Cada pago se guarda como gasto en la categoría protegida “Suscripción”, descuenta el medio elegido y actualiza el próximo vencimiento en una operación atómica.
- **Configuración:** permite gestionar las opciones disponibles de la aplicación.
- **Navegación lateral:** permite acceder desde un solo menú a todas las secciones de la aplicación.
- **Formato de dinero:** utiliza puntos como separadores de miles para facilitar la lectura de cantidades grandes, por ejemplo, `$ 50.000`.
- **Interfaz adaptable:** está desarrollada con Flutter para ofrecer una experiencia de uso en dispositivos compatibles.
- **Persistencia local:** conserva los registros en el almacenamiento local del dispositivo.

## Módulos de la aplicación

### 1. Inicio

Es la pantalla principal de MichiFinanzas. Presenta el total junto con efectivo y digital, resume las primeras cuentas digitales, y muestra ingresos del mes, gastos recientes, próximas suscripciones y gastos futuros. También ofrece accesos a registrar ingresos y gastos, consultar el historial, distribuir fondos y administrar las cuentas.

Su propósito es ofrecer una visión general del dinero registrado y facilitar el acceso a las funciones más utilizadas.

### 2. Ingresos

Este módulo independiente muestra el historial de ingresos y permite agregar, editar o eliminar registros. Cada nuevo ingreso debe distribuirse completamente entre efectivo y cuentas digitales; se pueden combinar varios destinos en una sola operación. Admite tres tipos de ingreso:

- **Sueldo:** dinero recibido por el trabajo.
- **Extra:** ingresos adicionales.
- **Préstamo:** dinero recibido mediante un préstamo, que también se registra como una deuda para realizar su seguimiento.

Los ingresos se acumulan en lugar de reemplazar automáticamente el dinero registrado anteriormente.

El objetivo es mantener un registro de las entradas de dinero y facilitar el cálculo del saldo disponible.

### 3. Gastos

Permite registrar las salidas de dinero y organizarlas según su categoría.

Entre sus funcionalidades se encuentran:

- Registrar nuevos gastos.
- Clasificar los movimientos.
- Consultar los gastos registrados.
- Editar un gasto después de guardarlo.
- Visualizar las cantidades utilizando separadores de miles.

La clasificación de los gastos permite identificar en qué se utiliza el dinero y facilita el análisis posterior.

Las categorías se pueden crear y renombrar desde Configuración. Una categoría con gastos asociados no se puede eliminar para proteger el historial.

### 4. Deudas

Este módulo está diseñado para llevar un seguimiento de las obligaciones económicas.

Permite organizar información relacionada con el valor de una deuda, el dinero abonado, el saldo pendiente y las cuotas correspondientes.

También contempla información como las fechas de vencimiento y el número de cuotas, de acuerdo con los datos registrados para cada obligación.

Cuando se registra dinero recibido mediante un préstamo desde el módulo de ingresos, la aplicación también crea el registro correspondiente en deudas para facilitar su seguimiento.

### 5. Gastos futuros

Esta sección permite organizar gastos que se espera realizar más adelante.

Su funcionamiento contempla dos acciones principales:

- **Confirmar una reserva:** confirma el gasto futuro y descuenta el importe reservado del saldo disponible.
- **Cancelar una reserva:** cancela la operación sin descontar dinero del saldo.

La aplicación busca evitar que una misma reserva descuente dinero más de una vez. Los movimientos relacionados con las reservas también se consideran en las estadísticas, de acuerdo con la lógica implementada.

### 6. Estadísticas

El módulo de estadísticas presenta información visual sobre los movimientos financieros registrados.

Incluye análisis generales, de efectivo y digitales por categoría, además de la evolución de los gastos pagados. Los pagos de deuda se cuentan una sola vez y las reservas futuras se muestran aparte, no como gastos realizados.

Entre sus componentes se encuentran:

- Gráficos de dona con gastos por categoría y dinero restante solo cuando existe una base comparable.
- Gráficos de barras para visualizar los gastos diarios.
- Filtros para consultar diferentes períodos.
- Estados de carga, errores y ausencia de información.

Esta sección permite comprender mejor los hábitos de consumo y detectar oportunidades para administrar el dinero de una forma más organizada.

### 7. Ahorros

La aplicación incluye una sección dedicada al seguimiento del ahorro, como parte de sus herramientas para organizar las finanzas personales.

Su finalidad es facilitar la revisión del dinero destinado a objetivos de ahorro y complementar el control de ingresos y gastos.

### 8. Suscripciones

Permite crear, editar, cancelar y reactivar servicios recurrentes con precio, frecuencia, próxima fecha de cobro y medio de pago habitual. La acción **Pagar** solicita confirmación y el origen (efectivo o una cuenta digital concreta), valida el saldo, registra el gasto asociado a la categoría protegida “Suscripción” y avanza el vencimiento dentro de una transacción. El historial de pagos se conserva incluso al cancelar una suscripción; no se realizan cobros automáticos.

Los datos de suscripciones y pagos se almacenan en SQLite local y se conservan al reiniciar la aplicación. La migración de esquema v15 agrega el estado de suscripción, la cuenta digital habitual y los vínculos únicos de período entre pagos y suscripciones; v16 agrega destinos persistentes para ingresos distribuidos. Ambas migraciones son aditivas.

### 9. Configuración

Permite guardar o cambiar el nombre local del usuario, administrar las categorías de gastos y crear o renombrar cuentas digitales. Las cuentas con historial no se eliminan; las transferencias internas se pueden consultar, editar o revertir desde esta sección.

---

## Tecnologías utilizadas

MichiFinanzas está construida con tecnologías del ecosistema Flutter y herramientas que permiten desarrollar, almacenar y probar la aplicación.

| Tecnología | Uso dentro del proyecto |
|---|---|
| Flutter | Framework para desarrollar la interfaz y la aplicación multiplataforma. |
| Dart | Lenguaje de programación utilizado para implementar la lógica de la aplicación. |
| Drift | Biblioteca para gestionar la base de datos y las consultas de forma estructurada. |
| SQLite | Motor de base de datos local utilizado en las plataformas compatibles. |
| fl_chart | Biblioteca utilizada para construir gráficos y visualizar estadísticas financieras. |
| Flutter Test | Herramientas para ejecutar pruebas automatizadas del proyecto. |
| Git | Control de versiones del código fuente. |
| GitHub | Alojamiento del repositorio y gestión del código del proyecto. |
| Android SDK y Gradle | Herramientas utilizadas para compilar la aplicación para Android. |

### ¿Por qué se utilizaron estas tecnologías?

**Flutter y Dart:** permiten desarrollar interfaces y funcionalidades en un mismo proyecto, evitando tener que construir toda la aplicación desde cero para cada plataforma.

**Drift y SQLite:** permiten almacenar y consultar los datos financieros mediante tablas y operaciones estructuradas. Esto ayuda a mantener organizados los ingresos, los gastos y las deudas.

**fl_chart:** facilita la representación gráfica de los datos para que la información financiera sea más comprensible.

**Git y GitHub:** permiten conservar el historial del código, organizar cambios y compartir el proyecto con otras personas.

---

## Almacenamiento de la información

MichiFinanzas utiliza una base de datos local administrada mediante Drift.

La implementación se encuentra principalmente en:

- `lib/database/app_database.dart`
- `lib/database/app_database.g.dart`
- `lib/services/database_service.dart`

El archivo generado `app_database.g.dart` contiene código de soporte producido por Drift. No debe editarse manualmente, ya que se genera a partir de la definición de la base de datos.

### ¿Cómo funciona el almacenamiento?

Cuando una persona registra un movimiento, la aplicación utiliza sus servicios y operaciones de base de datos para guardar la información. Posteriormente, las pantallas pueden consultar esos registros para actualizar los saldos, las listas y los gráficos.

Este enfoque permite conservar los datos entre aperturas de la aplicación sin depender de un servidor remoto para las operaciones locales.

### ¿Los datos se comparten entre celulares?

No. En la versión actual, cada instalación mantiene sus propios datos locales.

Por ejemplo, si una persona registra un gasto en su celular, ese movimiento no aparece automáticamente en el teléfono de otra persona.

La publicación de la APK permite distribuir e instalar la aplicación, pero no sincroniza los registros financieros entre usuarios.

---

## Cómo funciona la aplicación

El proyecto organiza las responsabilidades en diferentes partes para separar la interfaz, la lógica y el almacenamiento.

De manera general, el funcionamiento sigue este flujo:

1. La persona abre la aplicación y accede al módulo que necesita.
2. La pantalla muestra los datos disponibles o presenta un formulario para registrar información.
3. La persona introduce los datos y confirma la operación.
4. La aplicación valida y procesa la información correspondiente.
5. Los servicios realizan las operaciones necesarias sobre la base de datos local.
6. Las pantallas actualizan la información para reflejar los cambios.
7. El módulo de estadísticas consulta los movimientos disponibles y presenta los resultados mediante gráficos.

Esta separación ayuda a mantener el código organizado y permite modificar una funcionalidad sin tener que concentrar toda la lógica en una sola pantalla.

---

## Estructura del proyecto

La estructura principal del código fuente está organizada de la siguiente manera:

```text
finanzas_app/
├── android/
│   └── Configuración de la aplicación Android
├── assets/
│   └── app_icon/
├── ios/
│   └── Configuración de la aplicación iOS
├── lib/
│   ├── database/
│   │   ├── app_database.dart
│   │   └── app_database.g.dart
│   ├── models/
│   │   ├── future_expense.dart
│   │   ├── income_type.dart
│   │   └── subscription.dart
│   ├── screens/
│   │   ├── debts/
│   │   ├── expenses/
│   │   ├── future_expenses/
│   │   ├── home/
│   │   ├── savings/
│   │   ├── settings/
│   │   ├── statistics/
│   │   ├── subscriptions/
│   │   └── main_navigation_screen.dart
│   ├── services/
│   │   ├── app_settings_service.dart
│   │   ├── database_service.dart
│   │   ├── settings_storage_io.dart
│   │   ├── settings_storage_stub.dart
│   │   └── settings_storage_web.dart
│   ├── theme/
│   │   └── app_theme.dart
│   ├── utils/
│   │   ├── date_format.dart
│   │   ├── future_expense_calculator.dart
│   │   ├── money_format.dart
│   │   └── user_messages.dart
│   ├── widgets/
│   │   ├── cat_illustration.dart
│   │   └── section_placeholder.dart
│   ├── assets/
│   │   └── image/
│   └── main.dart
├── test/
│   └── Pruebas automatizadas
├── web/
│   └── Archivos de soporte para Flutter Web
├── windows/
│   └── Configuración de la plataforma Windows
├── linux/
│   └── Configuración de la plataforma Linux
├── macos/
│   └── Configuración de la plataforma macOS
├── pubspec.yaml
├── pubspec.lock
├── analysis_options.yaml
├── .gitignore
└── README.md
```

### Responsabilidad de las carpetas principales

- **`database/`:** define la estructura de almacenamiento y el código generado para las operaciones con Drift.
- **`models/`:** contiene modelos que representan información utilizada por la aplicación.
- **`screens/`:** agrupa las pantallas de los diferentes módulos financieros.
- **`services/`:** concentra servicios relacionados con la base de datos y la configuración.
- **`theme/`:** define el tema visual de la aplicación.
- **`utils/`:** reúne funciones auxiliares para formatos, cálculos y mensajes.
- **`widgets/`:** contiene componentes reutilizables de la interfaz.
- **`assets/`:** almacena ilustraciones y recursos gráficos.
- **`test/`:** contiene las pruebas automatizadas para verificar diferentes funcionalidades.

---

##  Requisitos para ejecutar el proyecto

Para trabajar con el código fuente se necesita un entorno compatible con Flutter.

Requisitos principales:

- Windows, macOS o Linux compatible con Flutter.
- Flutter SDK.
- Dart SDK, incluido con Flutter.
- Git.
- Un editor de código, como Visual Studio Code.
- Android SDK y las herramientas de compilación correspondientes si se desea generar una APK.
- Un dispositivo Android o un emulador para ejecutar y probar la aplicación.

La versión exacta de Flutter y las dependencias utilizadas pueden consultarse en el entorno de desarrollo y en los archivos de configuración del proyecto.


## Privacidad y limitaciones

MichiFinanzas está diseñada para mantener los registros financieros de cada instalación en el almacenamiento local del dispositivo.

Es importante tener en cuenta lo siguiente:

- Los datos de un teléfono no se sincronizan automáticamente con otro.
- Eliminar los datos de la aplicación o desinstalarla puede ocasionar la pérdida de los registros locales.
- Cambiar de dispositivo no transfiere automáticamente la base de datos anterior.
- El repositorio contiene el código fuente de la aplicación, no los registros personales creados por cada usuario.
- La distribución mediante una APK no crea cuentas de usuario ni proporciona sincronización en la nube.

Para una versión futura con sincronización entre dispositivos sería necesario implementar un servicio remoto, autenticación, reglas de acceso y mecanismos para mantener consistentes los movimientos financieros.

La protección de los datos locales también depende de la seguridad del dispositivo y de las medidas que tome cada usuario para conservar su información.


##  Autor

**Anderson Topaga Robles**

Proyecto personal de desarrollo de software orientado a la administración de finanzas personales.

**MichiFinanzas — Organiza tu dinero, entiende tus gastos y construye mejores hábitos financieros.** 💜
