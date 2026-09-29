# Reglas de Desarrollo Móvil (Flutter & Dart)

## 1. Rol y Comportamiento
- Priorizar el rendimiento nativo a 60 fps, la gestión eficiente del ciclo de vida y la estabilidad de las librerías nativas (GPS, Notificaciones).
- **Cero Comentarios Básicos:** PROHIBIDO generar código con comentarios obvios. El código debe autodocumentarse. Solo añadir líneas si la lógica involucra cálculos matemáticos (ej. Haversine) o interacciones con hardware opaco.
- **Idioma Español Absoluto:** Todo el código (clases, variables, métodos, widgets) y los nombres de archivos (`.dart`) y carpetas DEBEN estar estrictamente en español. (Ej: `lib/pantallas/inicio_sesion_pantalla.dart`).
- *Excepción:* Dependencias de `pubspec.yaml`, configuraciones raíz y llamadas a la API estándar de Flutter/Dart.

## 2. Estructura Base de Carpetas (Arquitectura por Módulos y Funcionalidad)
Se subdividirá la capa móvil (`bumand-movil/lib/`) para evitar un monolito inmanejable y mantener absoluta coherencia en español:
- `lib/nucleo/`: Configuración general, constantes, paleta de colores, rutas, y utilidades transversales.
- `lib/modulos/`: Separado por dominios de la aplicación:
  - `autenticacion/` (modelos, pantallas, proveedores, repositorios para inicio de sesión)
  - `pasajes/` (lógica de declaración de pasajes e ida/vuelta)
  - `asistencia/` (gestión de GPS y geocercas)
  - `inicio/` (pantallas principales del contenedor de navegación)
- `lib/widgets-comunes/`: Componentes UI reutilizables (botones personalizados, inputs).

## 3. Estándar de Código y Nombrado
- **snake_case:** Variables y Atributos (ej. `correo_controlador`, `becario_id`, `estado_actual`).
- **camelCase:** Métodos y funciones (ej. `iniciarSesion()`, `obtenerPerfil()`).
- **PascalCase (ESPAÑOL):** Clases, Interfaces, DTOs, Entidades, Widgets (ej. `class PerfilBecarioPantalla extends StatelessWidget`).
- **UPPER_SNAKE_CASE:** Constantes.
- **kebab-case:** Nombres de carpetas y archivos (ej. `inicio-sesion-pantalla.dart`, `usuario-modelo.dart`), y rutas de red REST.

## 4. Manejo de Estado y Rendimiento
- **Separación de Lógica y UI:** La capa de presentación (UI) nunca debe contener lógica de llamadas HTTP directas. Usar un gestor de estado (Riverpod, Provider o Bloc) de manera consistente.
- **Tipado Fuerte en Dart:** Usar `final` y `const` de manera obsesiva en todos los Widgets y constructores para optimizar el árbol de renderizado de Flutter.
- **Manejo de Nulos:** Aprovechar el `null-safety` estricto de Dart. NUNCA forzar un unwrap (`!`) sin validación previa.

## 5. Límites
- NUNCA modificar configuraciones nativas de `android/` o `ios/` (como `AndroidManifest.xml`) sin justificar la necesidad (ej. permisos GPS o Push) y consultar al usuario.
