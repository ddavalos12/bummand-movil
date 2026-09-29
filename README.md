# BUMAND Móvil (`bumand-movil`)

Aplicación móvil oficial del ecosistema **BUMAND** para becarios, desarrollada en **Flutter (Dart)** bajo principios de **Clean Architecture** y gestión de estado reactiva con **Riverpod**.

---

## 📱 Objetivos y Funcionalidades

- **Control de Asistencia:** Marcación de entrada y salida con soporte para geocercas universitarias y validación de coordenadas GPS.
- **Declaración de Pasajes (Viáticos):** Registro de trayectos de ida y vuelta con cálculo automático de devolución del $80\%$ de los gastos de transporte.
- **Seguimiento Académico:** Consulta del estado de evaluaciones pastorales (Formulario F-03) y avance semestral.
- **Navegación Intuitiva:** Barra inferior con pestañas para Inicio, Asistencia, Pasajes y Perfil.

---

## 🏗️ Estructura del Proyecto (Clean Architecture)

El código fuente en `lib/` está organizado en capas independientes y testeables:

```text
lib/
├── nucleo/                        # Componentes transversales
│   ├── constantes/
│   │   └── api-constantes.dart    # URLs base y endpoints REST
│   ├── tema/
│   │   └── colores.dart           # Paleta de colores BUMAND
│   └── utilidades/
│       └── resultado.dart         # Patrón Result (Exito<T> / Fallo<T>)
├── modulos/                       # Módulos funcionales desacoplados
│   ├── autenticacion/             # Inicio de sesión y token
│   │   ├── modelos/usuario-modelo.dart
│   │   ├── repositorios/autenticacion-repositorio.dart
│   │   ├── proveedores/autenticacion-proveedor.dart
│   │   └── pantallas/inicio-sesion-pantalla.dart, registro-pantalla.dart
│   ├── asistencia/                # Marcación de horas y geocercas
│   │   ├── datos/universidades.dart
│   │   ├── modelos/tipo-asistencia.dart
│   │   ├── repositorios/asistencia-repositorio.dart
│   │   ├── proveedores/asistencia-proveedor.dart
│   │   └── pantallas/asistencia-pantalla.dart, confirmar-datos-pantalla.dart
│   ├── pasajes/                   # Declaración y cálculo del 80%
│   │   ├── modelos/recorrido-modelo.dart, solicitud-pasaje-modelo.dart
│   │   ├── utilidades/formato-pasajes.dart
│   │   ├── repositorios/pasajes-repositorio.dart
│   │   ├── proveedores/pasajes-proveedor.dart
│   │   └── pantallas/pasajes-pantalla.dart, declarar-recorrido-pantalla.dart
│   └── inicio/                    # Pantalla principal y menú inferior
│       └── pantallas/pantalla-inicio.dart
├── widgets-comunes/               # Widgets visuales reutilizables
└── main.dart                      # Punto de entrada (ProviderScope)
```

---

## 📐 Estándar Estricto de Código y Nombrado

En consonancia con las reglas corporativas de BUMAND:

| Convención | Ámbito de Aplicación | Ejemplo |
| :--- | :--- | :--- |
| **`snake_case`** | Variables, atributos, parámetros de estado | `becario_id`, `correo`, `hora_entrada` |
| **`camelCase`** | Métodos y funciones | `iniciarSesion()`, `registrarAsistencia()` |
| **`PascalCase`** | Clases, modelos, entidades y Widgets | `UsuarioModelo`, `InicioSesionPantalla` |
| **`UPPER_SNAKE_CASE`** | Constantes | `URL_BASE_LOCAL`, `COLOR_PRIMARIO` |
| **`kebab-case`** | Archivos y nombres de carpetas | `inicio-sesion-pantalla.dart`, `nucleo/` |
| **Español Absoluto** | Todo el código fuente | Sin terminología en inglés no requerida |

*Nota:* El archivo `analysis_options.yaml` está configurado con `file_names: false` y `non_constant_identifier_names: false` para permitir nombres `kebab-case.dart` y variables `snake_case` con cero advertencias de análisis estático.

---

## 🚀 Comandos de Ejecución y Desarrollo

### 1. Instalación de Dependencias
```bash
flutter pub get
```

### 2. Análisis Estático de Código
```bash
flutter analyze
```

### 3. Ejecución de Pruebas Unitarias y de Widgets
```bash
flutter test
```

### 4. Encendido y Ejecución de la Aplicación

#### En emulador móvil o dispositivo físico conectado:
```bash
flutter run
```

#### En navegador web (Google Chrome):
```bash
flutter run -d chrome
```

#### En entorno de escritorio nativo Windows:
```bash
flutter run -d windows
```

---

## 📄 Documentación Técnica Completa

Se encuentra disponible la especificación formal en formato PDF:
- [documentacion_movil.pdf](file:///c:/Users/yang_/Desktop/Bumands-Proyecto/new-bumand/bumand-movil/documentacion_movil.pdf) (Generado con `generador-pdf` / LaTeX).
