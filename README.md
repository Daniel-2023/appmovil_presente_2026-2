#  Presente! — Control y Seguimiento de Asistencia Digital

**Presente!** es una aplicación móvil multiplataforma desarrollada en **Flutter** y conectada a **Firebase** para gestionar, validar y monitorear la asistencia académica en tiempo real mediante códigos QR dinámicos y justificantes digitales.

---

##  Características Principales

###  Autenticación y Gestión de Usuarios
* **Inicio de Sesión y Registro:** Acceso diferenciado por rol (**Docente** y **Estudiante**) con validaciones de formularios (`validator_Form.dart`).
* **Recuperación de Contraseña:** Flujo completo para restablecer y actualizar credenciales de acceso.

###  Módulo Docente
* **Gestión de Asignaturas:** Creación de cursos con horarios, aulas, códigos de sección e importación masiva de estudiantes desde archivos Excel (`.xlsx` / `.xls`).
* **Sesiones en Vivo con Código QR:** Generación instantánea de códigos QR únicos y PIN de respaldo por sesión de clase.
* **Marcación en Tiempo Real:** Visualización en vivo del porcentaje de asistencia, barra de progreso y listado alfabético sincronizado con Cloud Firestore.
* **Validación y Revisión de Excusas:** Validación manual individual o masiva (*"Validar Restantes"*) y revisión directa de excusas médicas o institucionales adjuntas en formato PDF (con aprobación o rechazo inmediato).

###  Módulo Estudiante
* **Panel Académico Personalizado:** Visualización del porcentaje global de asistencia semestral, alertas de sesiones activas en vivo y filtrado de asignaturas (*Todos mis cursos*, *Hoy*, *Por evaluar*).
* **Registro Rápido por QR:** Escaneo directo con cámara (`mobile_scanner`) para confirmar presencia al instante.
* **Envío de Justificantes en PDF:** Carga de documentos justificantes en formato PDF cuando el estudiante no puede asistir a clase.

---

##  Estructura y Descripción de Archivos

```text
proyecto_final/
├── lib/
│   ├── main.dart
│   └── src/
│       ├── docente/
│       │   ├── crear_asignatura.dart
│       │   ├── crear_asignatura2.dart
│       │   └── docente.dart
│       ├── estudiante/
│       │   ├── estudinte.dart
│       │   └── tomar_asistencia.dart
│       ├── registro/
│       │   ├── actualizar_password.dart
│       │   ├── recuperar_password.dart
│       │   └── registro.dart
│       ├── img/
│       │   ├── imgrecuperacontrasenia.png
│       │   └── logo.png
│       ├── login.dart
│       └── validator_Form.dart
└── test/
    └── widget_test.dart
