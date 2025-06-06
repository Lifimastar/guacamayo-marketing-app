# Guacamayo Marketing Solutions - Aplicación Móvil

![Guacamayo Marketing Logo](assets/images/logo.png) 

¡Bienvenido al repositorio de la aplicación móvil de Guacamayo Marketing Solutions! Esta aplicación es un marketplace de servicios de marketing digital, diseñada para conectar a nuestros clientes con una amplia gama de soluciones creativas y estratégicas.

## 🚀 Características Principales

La aplicación ofrece una experiencia completa tanto para clientes como para administradores:

### Para Clientes
- **Autenticación Segura:** Registro e inicio de sesión de usuarios con gestión de perfiles.
- **Catálogo de Servicios:** Explora una variedad de servicios de marketing digital (SEO, redes sociales, publicidad, diseño web, etc.) con descripciones detalladas e imágenes de portada.
- **Reserva y Pago en Línea:** Proceso intuitivo para reservar servicios y completar pagos de forma segura a través de Stripe.
- **Gestión de Reservas:** Visualiza el historial y el estado actual de tus reservas.
- **Entregables:** Accede a los archivos y recursos entregables asociados a tus proyectos.
- **Reseñas y Calificaciones:** Deja feedback sobre los servicios completados para ayudar a otros usuarios.

### Para Administradores
- **Panel de Administración Centralizado:** Gestiona todos los aspectos del marketplace desde la aplicación.
- **Gestión de Reservas:** Visualiza, filtra y actualiza el estado de todas las reservas de los clientes.
- **Gestión de Servicios:** Crea, edita, activa/desactiva y elimina servicios del catálogo. Incluye la subida de imágenes de portada.
- **Gestión de Entregables:** Sube y gestiona archivos entregables para cada reserva.
- **Gestión de Usuarios:** Visualiza la lista de usuarios, cambia sus roles (cliente/administrador) y elimina usuarios de forma segura.

## 🛠️ Tecnologías Utilizadas

### Frontend (Esta Aplicación)
- **Flutter:** Framework de UI para construir aplicaciones nativas compiladas para móvil, web y escritorio desde una única base de código.
- **Dart:** Lenguaje de programación.
- **Riverpod:** Para una gestión de estado robusta y escalable.
- **Supabase (SDK Flutter):** Backend-as-a-Service para autenticación, base de datos (PostgreSQL) y almacenamiento de archivos.
- **Flutter Stripe:** Integración con la pasarela de pagos Stripe para procesar transacciones.
- **`file_picker`:** Para seleccionar archivos del dispositivo.
- **`url_launcher`:** Para abrir enlaces externos (WhatsApp, sitios web, etc.).
- **`flutter_svg`:** Para renderizar imágenes SVG.
- **`logger`:** Para un logging estructurado en desarrollo y producción.
- **`font_awesome_flutter`:** Para iconos adicionales.

### Backend (Servicios Adicionales)
- **FastAPI (Python):** Framework web de alto rendimiento para construir APIs REST.
- **Supabase (Librería Python):** Para interactuar con la base de datos y servicios de autenticación de Supabase desde el backend.
- **Stripe (Librería Python):** Para interactuar de forma segura con la API de Stripe (creación de Payment Intents, verificación de webhooks).
- **`python-dotenv`:** Para gestionar variables de entorno localmente.
- **Uvicorn:** Servidor ASGI para ejecutar aplicaciones FastAPI.

## ⚙️ Configuración del Entorno de Desarrollo

Sigue estos pasos para configurar y ejecutar la aplicación en tu entorno local.

### 1. Requisitos Previos
- [Flutter SDK](https://flutter.dev/docs/get-started/install) (versión estable, verifica `flutter doctor`)
- [Android Studio](https://developer.android.com/studio) (para emulador/dispositivo Android)
- [VS Code](https://code.visualstudio.com/) (IDE recomendado)
- [Git](https://git-scm.com/downloads)
- [Python 3.8+](https://www.python.org/downloads/) (para el backend)
- [pip](https://pip.pypa.io/en/stable/installation/) (gestor de paquetes de Python)
- [Supabase CLI](https://supabase.com/docs/guides/cli)
- [Deno](https://deno.land/#installation) (para Supabase Edge Functions)
- [Docker Desktop](https://docs.docker.com/desktop/install/) (si planeas ejecutar Supabase localmente)

### 2. Clonar los Repositorios

Asegúrate de clonar ambos repositorios en una carpeta raíz común (ej: `proyectos/`).

```bash
# En tu carpeta de proyectos (ej: C:\Users\tu_usuario\proyectos\)
git clone https://github.com/Lifimastar/guacamayo-marketing-app.git
git clone https://github.com/Lifimastar/guacamayo-marketing-backend.git
```

### 3. Configuración de Supabase

1. #### Crear Proyecto en Supabase Cloud:
*  Ve a [Supabase Dashboard](https://supabase.com/dashboard).
*  Crea un nuevo proyecto. Anota tu **Project URL** y **anon public key** (se encuentran en Project Settings -> API).

2. #### Configurar Tablas y RLS:
* Utiliza el `Table editor` en el dashboard de Supabase para crear las siguientes tablas con sus respectivas columnas y configurar las políticas de **Row Level Security (RLS)** como se discutió durante el desarrollo:
  * `profiles`
  * `services`
  * `bookings`
  * `deliverables`
  * `payments`
  * `reviews`
* **Importante:** Asegúrate de que las Foreign Keys y las políticas RLS estén configuradas exactamente como se especificó para cada tabla, incluyendo la función `public.is_admin()` y sus correspondientes `GRANT EXECUTE`.

3. #### Configurar Supabase Storage Buckets:
* Crea los siguientes buckets en la sección **Storage** del dashboard de Supabase:
  * `service-covers` (Debe ser Público, con una política que permita a los administradores realizar operaciones INSERT/UPDATE/DELETE).
  * `deliverables` (Debe ser Privado, con políticas que permitan a los administradores realizar operaciones CRUD y a los clientes realizar SELECT de sus propios entregables).

4. #### Vincular Supabase CLI (Opcional, principalmente para Edge Functions y Migraciones):
* En la raíz de tu proyecto Flutter (por ejemplo, `guacamayo-marketing-app`):
```bash
supabase login
supabase link --project-ref YOUR_SUPABASE_PROJECT_ID 
# Reemplaza YOUR_SUPABASE_PROJECT_ID con el ID de tu proyecto de Supabase
```

5. #### Configurar Secreto de Stripe para Edge Function:
* En la raíz de tu proyecto Flutter (`guacamayo-marketing-app`):
```
supabase secrets set STRIPE_SECRET_KEY=sk_test_YOUR_STRIPE_SECRET_KEY # Usa tu clave secreta de PRUEBA de Stripe
```

6. #### Desplegar Edge Function create-payment-intent:
* En la raíz de tu proyecto Flutter (`guacamayo-marketing-app`):
```
supabase functions deploy create-payment-intent --no-verify-jwt
```
* Copia la URL pública de la función desplegada.

### 4. Configuración del Backend (FastAPI)
1. #### Navegar al Directorio del Backend:
```
cd guacamayo-marketing-backend
```

2. #### Crear y Activar Entorno Virtual:
```
python -m venv .venv
# Windows: .venv\Scripts\activate
# macOS/Linux: source .venv/bin/activate
```
3. #### Instalar Dependencias:
```
pip install -r requirements.txt # Asegúrate de que requirements.txt esté actualizado
```
(Si no tienes `requirements.txt`, ejecuta   
`pip install fastapi uvicorn stripe supabase python-dotenv` y luego   
`pip freeze > requirements.txt`).

4. #### Configurar Archivo .env:
* Crea un archivo `.env` en la raíz de tu carpeta `guacamayo-marketing-backend`.
* Añade tus claves secretas (de PRUEBA) y URLs:
```
STRIPE_SECRET_KEY=sk_test_YOUR_STRIPE_SECRET_KEY
STRIPE_WEBHOOK_SIGNING_SECRET=whsec_YOUR_STRIPE_WEBHOOK_SIGNING_SECRET # Obtendrás esta de Stripe
SUPABASE_URL=https://YOUR_SUPABASE_PROJECT_REF.supabase.co
SUPABASE_SERVICE_ROLE_KEY=YOUR_SUPABASE_SERVICE_ROLE_KEY # Clave service_role_key de Supabase
```

5. #### Desplegar el Backend (Ej: Render):
* Sube tu repositorio `guacamayo-marketing-backend` a GitHub.
* Despliega el servicio web en una plataforma como [Render](https://render.com/) (o DigitalOcean, AWS, etc.).
* Configura las variables de entorno en la plataforma de despliegue con los mismos valores del `.env` (¡no subas el archivo `.env`!).
* Obtén la URL pública de tu backend desplegado (ej: `https://guacamayo-marketing-webhook.onrender.com`).

6. #### Configurar Webhook en Stripe:
* Ve a [Stripe Dashboard](https://dashboard.stripe.com/login?redirect=%2Ftest%2Fwebhooks) (modo prueba).
* Añade un nuevo endpoint de webhook.
* **Endpoint URL:** `https://YOUR_BACKEND_URL/stripe-webhook` (ej: `https://guacamayo-marketing-webhook.onrender.com/stripe-webhook`).
* **Select events to send:** `payment_intent.succeeded`, `payment_intent.payment_failed`.
* Guarda el endpoint y **revela y copia la Signing secret**.
* Actualiza la variable `STRIPE_WEBHOOK_SIGNING_SECRET` en las variables de entorno de tu backend desplegado (y en tu `.env` local).

### 5. Configuración de la Aplicación Flutter
Navegar al Directorio de la Aplicación:
cd guacamayo-marketing-app
Use code with caution.
Bash
Instalar Dependencias:
flutter pub get
Use code with caution.
Bash
Configurar lib/utils/config.dart:
Abre este archivo y reemplaza los placeholders con tus claves y URLs reales:
const String supabaseUrl = 'YOUR_SUPABASE_URL';
const String supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';
const String stripePublishableKey = 'pk_test_YOUR_STRIPE_PUBLISHABLE_KEY';
const String paymentIntentBackendUrl = 'YOUR_EDGE_FUNCTION_URL'; // URL de la Edge Function
const String adminBackendUrl = 'YOUR_FASTAPI_BACKEND_URL'; // URL de tu backend de FastAPI en Render
Use code with caution.
Dart
Configurar Icono y Splash Screen:
Asegúrate de tener tu app_icon.png y splash_logo.png (y splash_logo_android12.png) en assets/icon/.
En pubspec.yaml, configura flutter_launcher_icons y flutter_native_splash.
Ejecuta:
flutter pub run flutter_launcher_icons
flutter pub run flutter_native_splash:create
Use code with caution.
Bash
Configurar Nombre y ID de Aplicación (Android):
En android/app/src/main/AndroidManifest.xml, actualiza android:label.
En android/app/build.gradle.kts, actualiza applicationId.
Configurar Firma de Release (Android):
Genera tu keystore (.jks) si no lo has hecho, y guárdalo en android/app/.
Crea android/key.properties (en la carpeta android/) y configúralo con tus contraseñas y la ruta al .jks.
Asegúrate de que android/app/build.gradle.kts esté configurado para usar key.properties y firmar el build de release.
¡Asegúrate de que key.properties y el archivo .jks estén en tu .gitignore!
6. Ejecutar la Aplicación
flutter clean
flutter pub get
flutter run
Use code with caution.
Bash
🧪 Pruebas
Realiza pruebas exhaustivas de todos los flujos de cliente y administrador para asegurar que todas las funcionalidades operan correctamente y que la experiencia de usuario es fluida.
📦 Compilar para Lanzamiento
Para generar el Android App Bundle (AAB) firmado, listo para subir a Google Play Console:
flutter build appbundle --release
Use code with caution.
Bash
El archivo AAB se encontrará en build/app/outputs/bundle/release/app-release.aab.
🤝 Contribución
Si este proyecto es de código abierto o si hay pautas para colaboradores, inclúyelas aquí.
