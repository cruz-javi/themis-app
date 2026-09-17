# Diseño visual de themis-app

Guía de estilo para la app móvil del votante, inspirada en la referencia visual compartida (app de running estilo "RunMate": tarjetas blancas flotantes sobre fondo gris claro, acento menta/verde agua, nav inferior en píldora negra, chips/badges negros redondeados). El objetivo es que **toda pantalla nueva** siga este mismo lenguaje visual en vez de inventar un estilo por feature.

> Los valores de color base (`ink`, `background`/paper, `accent`) son los oficiales de la identidad de marca Themis (logo + guía de marca). El resto de tokens derivados (`accent-strong`, `ink-soft`, `border-subtle`, `error`) siguen siendo estimaciones a partir de la referencia visual "RunMate" — ajustar en `main.dart`/`ThemeData` si al implementar se ve necesario, pero mantener la relación entre ellos (fondo muy claro tipo "paper", tarjetas blancas, un solo acento de color, `ink` para elementos de navegación/énfasis).

## 1. Paleta de color

| Token | Hex | Uso |
|---|---|---|
| `background` (paper) | `#F8FAFC` | Fondo de toda pantalla (color oficial de marca "paper", nunca blanco puro) |
| `surface` (tarjetas) | `#FFFFFF` | Cards, hojas modales, campos de formulario |
| `accent` | `#12B39B` | Color oficial de marca. Barras de progreso, gráficos, anillos, highlights puntuales — **un solo acento**, no mezclar con otros colores de marca |
| `accent-strong` | `#0E8F7C` | Variante más saturada del acento (estimada, ~15% más oscura) para texto/iconos sobre fondo claro que necesiten más contraste que el acento plano |
| `ink` | `#0F172A` | Color oficial de marca. Nav inferior, chips de stats, texto principal, botones primarios |
| `ink-soft` | `#4A5568` | Texto secundario sobre fondo claro (estimado, variante suavizada de `ink`) |
| `on-ink` | `#FFFFFF` | Texto/iconos sobre fondo `ink` |
| `border-subtle` | `#E2E8F0` | Bordes muy sutiles entre tarjetas cuando no alcanza con la sombra (estimado, variante de `paper`) |
| `success` / `habilitado` | reusar `accent-strong` | Ya usado hoy en `login_result_page.dart` como verde de "habilitado" — no introducir un verde distinto |
| `error` | `#D64545` | Mensajes de error (login fallido, sin conexión) |

**Regla de un solo acento:** la referencia usa exactamente un color de marca (el mint) contra una base neutra blanco/gris/negro. No agregar un segundo color de acento sin una razón fuerte (ej. distinguir "habilitado" de "no habilitado" puede usar `accent-strong` vs `error`, pero no un tercer color nuevo).

### Dark mode

La referencia no define uno. Al implementarlo, invertir la relación (fondo `#121212`, tarjetas `#1E1E1E`) manteniendo el mismo acento mint — no lo oscurezcas, el mint debe seguir siendo el elemento que "salta" en ambos modos.

## 2. Tipografía

La referencia usa una sans-serif geométrica y redondeada (visualmente cercana a **Poppins** o **Manrope**). Usar una de esas dos vía `google_fonts` en vez de la fuente del sistema, para no perder ese carácter.

| Estilo | Tamaño | Peso | Uso |
|---|---|---|---|
| Display | 28–32 | Bold (700) | Números grandes destacados (ej. "9 Level", "10 km", "43/90") |
| Título de pantalla | 20–22 | SemiBold (600) | "Explore and adjust", títulos de `AppBar` |
| Título de sección | 16–18 | SemiBold (600) | "Check your stats", "Your Activity" |
| Cuerpo | 14 | Regular/Medium (400/500) | Texto normal, labels de campos |
| Caption | 11–12 | Medium (500) | Etiquetas pequeñas bajo íconos, timestamps del gráfico |

Jerarquía por **peso y tamaño**, no por color — el texto casi siempre es `ink` o `ink-soft`, el color se reserva para el acento y los estados.

## 3. Espaciado, radios y sombra

| Token | Valor | Uso |
|---|---|---|
| `radius-card` | 24px | Tarjetas grandes (el contenedor principal de cada sección) |
| `radius-chip` | 999px (pill) | Badges de stats, botones de nav inferior, chips de filtro |
| `radius-avatar` | círculo perfecto | Fotos de perfil/equipo, con borde blanco de ~2px si están sobre una foto/mapa |
| `spacing-page` | 20px | Padding horizontal de toda pantalla |
| `spacing-card` | 16–20px | Padding interno de las tarjetas |
| `spacing-stack` | 12px | Separación entre tarjetas consecutivas |
| Sombra | difusa, muy suave (`blur` alto, `opacity` baja, sin color, solo negro al 4-6%) | Las tarjetas "flotan" sutilmente sobre el fondo gris, nunca un borde duro |

Nada de esquinas rectas ni sombras duras — es el detalle que más define este estilo. Si un componente de Material 3 por defecto (radius 4-12px) se usa tal cual, no se va a ver igual a la referencia; hay que sobreescribir el `shape` explícitamente.

## 4. Componentes clave

- **Tarjeta de sección** (`Card` custom): fondo `surface`, `radius-card`, sombra suave, título en la esquina superior con acción secundaria alineada a la derecha (ej. "More >", "Day/W/Y").
- **Stat badge** (círculo negro con ícono + valor): fondo `ink`, ícono/texto en `on-ink`, tamaño compacto, usado para métricas puntuales (steps, heart rate, calories en la referencia — acá serían métricas de la elección: votos emitidos, tiempo restante, etc. si aplica a futuro).
- **Gráfico de barras**: barras en `accent`, la barra "activa"/seleccionada más alta u oscura (`accent-strong`), fondo transparente sobre la tarjeta blanca, sin ejes ni grillas visibles — solo las barras y labels de tiempo abajo.
- **Anillo/barra de progreso circular o lineal**: trazo en `accent`, fondo del track en un gris muy claro (`border-subtle`), texto del valor centrado en `ink`.
- **Nav inferior en píldora**: contenedor `ink` con `radius-chip`, flotando con margen respecto a los bordes de la pantalla (no pegado ni full-width), 3 íconos en `on-ink`, el ítem activo con un círculo `on-ink`/`surface` de fondo detrás del ícono.
- **Chips de equipo/avatares**: círculos con foto + un círculo `+` en `border-subtle` para "agregar", en fila horizontal con scroll si no entran.
- **Mapa/ruta**: trazo de ruta en `accent`, controles flotantes (play/pause, stop) en círculos blancos con sombra sobre el mapa, no integrados a la tarjeta.

## 5. Cómo aplicarlo en Flutter

Hoy `main.dart` define el tema así:

```dart
theme: ThemeData(
  colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0F172A)),
  useMaterial3: true,
),
```

Esto genera una paleta Material 3 automática a partir de un solo seed, que **no** va a reproducir este estilo (Material 3 por defecto usa esquinas más chicas y no tiene el patrón "fondo gris + tarjetas blancas + acento único + negro para nav"). Para adoptar esta guía, reemplazar por un `ColorScheme` explícito en vez de `fromSeed`, y sobreescribir los temas de componente (`cardTheme`, `elevatedButtonTheme`, `chipTheme`, etc.) con los radios y colores de las secciones 1 y 3. Sugerido:

```dart
theme: ThemeData(
  useMaterial3: true,
  scaffoldBackgroundColor: const Color(0xFFF8FAFC),
  colorScheme: const ColorScheme.light(
    primary: Color(0xFF0F172A),
    secondary: Color(0xFF12B39B),
    surface: Color(0xFFFFFFFF),
    error: Color(0xFFD64545),
  ),
  textTheme: GoogleFonts.poppinsTextTheme(), // o manrope
  cardTheme: CardThemeData(
    color: Colors.white,
    elevation: 0,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
  ),
),
```

El nav inferior en píldora y los stat badges no tienen equivalente directo en Material 3 (`NavigationBar` es full-width y rectangular) — van a necesitar widgets custom (`Container` + `Row` + `BoxDecoration` con `borderRadius` circular), no una config de tema.

Pantallas ya existentes a re-visitar cuando se adopte esta guía: `lib/features/auth/login_page.dart`, `lib/features/auth/login_result_page.dart`, `lib/features/demo/demo_page.dart` (esta última es andamiaje temporal, no vale la pena re-diseñarla).

## 6. Qué NO hacer

- No usar los colores/`Card`/botones default de Material 3 sin sobreescribir `shape`/`elevation` — se nota inmediatamente que no sigue la guía.
- No introducir un segundo color de acento por pantalla "porque queda lindo" — un solo `accent` (teal de marca) en toda la app.
- No usar esquinas rectas en tarjetas ni sombras duras con color.
- No usar la fuente default del sistema si se puede agregar `google_fonts` — la tipografía redondeada es parte central del estilo.
