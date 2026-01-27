# 🛠️ TecniHogar - Plataforma de Servicios Técnicos

<div align="center">

![Flutter](https://img.shields.io/badge/Flutter-3.5.0-blue?logo=flutter)
![Dart](https://img.shields.io/badge/Dart-3.5.0-blue?logo=dart)
![Supabase](https://img.shields.io/badge/Supabase-Backend-green?logo=supabase)
![Firebase](https://img.shields.io/badge/Firebase-FCM-orange?logo=firebase)

**Aplicación móvil que conecta clientes con técnicos especializados en tiempo real**

[Características](#-características) • [Instalación](#-instalación-rápida) • [Demo](#-demo) • [Arquitectura](#-arquitectura)

</div>

---

## 📱 Sobre el Proyecto

**TecniHogar** es una plataforma móvil multiplataforma (Android/iOS/Web) que facilita la conexión entre personas que necesitan servicios técnicos a domicilio y profesionales verificados cercanos. 

### 🎯 Problema

- ❌ Difícil encontrar técnicos confiables
- ❌ Sin transparencia en precios
- ❌ Proceso de contratación lento
- ❌ Sin seguimiento del servicio
- ❌ Falta de calificaciones verificadas

### ✅ Solución

- ✅ Técnicos verificados con geolocalización
- ✅ Sistema de cotizaciones competitivas
- ✅ Proceso digital rápido
- ✅ **Notificaciones push en tiempo real**
- ✅ Sistema completo de reseñas

---

## ✨ Características

### 👤 Para Clientes

- 📍 **Crear solicitudes** con fotos y ubicación GPS
- 💰 **Recibir múltiples cotizaciones** de técnicos cercanos
- 🔔 **Notificaciones push** cuando llegan cotizaciones
- 🗺️ **Ver técnicos en mapa** con distancias
- ⭐ **Calificar servicios** con ratings detallados

### 🔧 Para Técnicos

- 📍 **Ver solicitudes cercanas** en mapa interactivo (10km)
- 📤 **Enviar cotizaciones** personalizadas
- 🔔 **Notificaciones push** al aceptar/rechazar
- 💼 **Portfolio de trabajos** con galería
- ✅ **Verificación profesional** por admin
- 📊 **Perfil público** con ratings

### 👨‍💼 Para Administradores

- 🔍 **Verificar técnicos** (documentos, certificados)
- 📊 **Dashboard** con estadísticas
- 👥 **Gestionar usuarios** del sistema

---

## 🚀 Instalación Rápida

### Prerequisitos

```bash
Flutter SDK 3.5.0+
Dart SDK 3.5.0+
Git
```

### 1. Clonar Repositorio

```bash
git clone https://github.com/misael-g/serviciosd_app.git
cd serviciosd_app
```

### 2. Instalar Dependencias

```bash
flutter pub get
```

### 3. Configurar Variables de Entorno

Crear `.env` en la raíz:

```env
SUPABASE_URL=https://tu-proyecto.supabase.co
SUPABASE_ANON_KEY=tu-clave-publica
```

### 4. Configurar Backend

Ver [Manual de Despliegue](docs/MANUAL_DESPLIEGUE_COMPLETO.md) para:
- Crear proyecto Supabase
- Ejecutar scripts SQL
- Configurar Storage
- Configurar Firebase + Notificaciones

### 5. Ejecutar

```bash
# Android/iOS
flutter run

# Web
flutter run -d chrome
```

---

## 📂 Estructura del Proyecto

```
lib/
├── core/                       # Funcionalidades compartidas
│   ├── config/                 # Configuración (Supabase, Firebase)
│   ├── constants/              # Constantes y estados
│   ├── theme/                  # Tema visual
│   ├── utils/                  # Helpers (validadores, ubicación)
│   └── widgets/                # Widgets reutilizables
│
├── data/                       # Capa de datos
│   ├── datasources/            # Comunicación con backend
│   ├── models/                 # Modelos de datos (JSON ↔ Dart)
│   └── repositories/           # Implementación de repositorios
│
├── domain/                     # Capa de dominio
│   ├── entities/               # Entidades de negocio
│   └── repositories/           # Contratos de repositorios
│
└── presentation/               # Capa de presentación (UI)
    ├── admin/                  # Pantallas administrador
    ├── auth/                   # Login y registro
    ├── client/                 # Pantallas cliente
    ├── shared/                 # Componentes compartidos
    └── technician/             # Pantallas técnico
```

**Arquitectura:** Clean Architecture con 3 capas

---

## 🛠️ Stack Tecnológico

### Frontend

| Tecnología | Uso |
|------------|-----|
| ![Flutter](https://img.shields.io/badge/-Flutter-02569B?logo=flutter&logoColor=white) | Framework multiplataforma |
| ![Dart](https://img.shields.io/badge/-Dart-0175C2?logo=dart&logoColor=white) | Lenguaje de programación |
| **Provider** | State management |
| **Flutter Map** | Mapas interactivos |
| **Geolocator** | Geolocalización GPS |
| **Image Picker** | Cámara y galería |

### Backend

| Tecnología | Uso |
|------------|-----|
| ![Supabase](https://img.shields.io/badge/-Supabase-3ECF8E?logo=supabase&logoColor=white) | Backend as a Service |
| ![PostgreSQL](https://img.shields.io/badge/-PostgreSQL-336791?logo=postgresql&logoColor=white) | Base de datos |
| ![Firebase](https://img.shields.io/badge/-Firebase-FFCA28?logo=firebase&logoColor=black) | Notificaciones push (FCM) |
| **Edge Functions** | Serverless (Deno/TypeScript) |
| **PostGIS** | Extensión geoespacial |

### Servicios

- **OpenStreetMap** - Tiles de mapas
- **Firebase Cloud Messaging v1** - Push notifications
- **Supabase Auth** - Autenticación JWT

---

## 📊 Base de Datos

### Esquema Principal

```sql
profiles (usuarios)
  ↓
service_requests (solicitudes)
  ↓
quotations (cotizaciones)
  ↓
reviews (reseñas)
```

### Triggers Automáticos

- ✅ Crear perfil al registrarse
- ✅ Actualizar ratings al recibir reseña
- ✅ **Enviar notificación al crear cotización**
- ✅ **Enviar notificación al aceptar/rechazar**

---

## 🔔 Notificaciones Push

### Arquitectura

```
Trigger SQL → Edge Function → Firebase FCM v1 → Dispositivo
```

### Tipos de Notificaciones

**1. Nueva Cotización (Cliente)**
```
💰 Nueva Cotización
María García envió una cotización para "Reparar luz"
```

**2. Cotización Aceptada (Técnico)**
```
🎉 ¡Cotización Aceptada!
Juan Pérez aceptó tu cotización
```

**3. Cotización Rechazada (Técnico)**
```
❌ Cotización Rechazada
Juan Pérez rechazó tu cotización
```

### Tecnología

- **FCM v1 API** (moderna, no legacy)
- **OAuth 2.0** con JWT
- **Edge Functions** en Deno/TypeScript
- **Tokens seguros** en Supabase Secrets

---

## 🔐 Seguridad

### Autenticación

- **JWT Tokens** con refresh automático
- **Almacenamiento seguro** en dispositivo
- **Email verification**

### Row Level Security (RLS)

Todas las tablas protegidas con políticas:

```sql
-- Ejemplo: Solo el cliente ve sus solicitudes
CREATE POLICY "clients_view_own_requests"
  ON service_requests FOR SELECT
  USING (client_id = auth.uid());
```

### Storage

- **Buckets públicos:** profile-images, service-images
- **Buckets privados:** documents (solo admin)
- **Políticas granulares** por rol

---

## 📖 Documentación

- 📘 [Manual de Despliegue](docs/MANUAL_DESPLIEGUE_COMPLETO.md)
- 📙 [Arquitectura del Sistema (JSON)](docs/arquitectura_sistema.json)
- 📗 [Documentación de API](docs/DOCUMENTACION_API.md)
- 📕 [Guía de Notificaciones Push](docs/NOTIFICACIONES_SIN_CLI.md)

---

## 🎨 Capturas de Pantalla

<div align="center">

### Cliente

![WhatsApp Image 2026-01-24 at 1 56 54 PM (1)](https://github.com/user-attachments/assets/f8357ff1-202d-456c-b085-fe3fb56d1d47)

### Técnico

![WhatsApp Image 2026-01-24 at 1 56 54 PM](https://github.com/user-attachments/assets/72232b28-ebdf-4cad-837a-b14c59143281)

</div>

---

## 🧪 Testing

```bash
# Ejecutar tests
flutter test

# Análisis de código
flutter analyze

# Verificar formato
flutter format --set-exit-if-changed .
```

---

## 📦 Build

### Android

```bash
# APK
flutter build apk --release

# App Bundle (Play Store)
flutter build appbundle --release
```

### iOS

```bash
flutter build ios --release
```

### Web

```bash
flutter build web --release
```

---

## 🚀 Deployment

### Google Play

1. `flutter build appbundle --release`
2. Subir a Google Play Console
3. Completar información
4. Enviar para revisión

### Web

```bash
flutter build web --release
# Subir carpeta build/web/ a servidor
```

---

## 🤝 Contribuir

¡Las contribuciones son bienvenidas!

1. Fork el proyecto
2. Crear rama: `git checkout -b feature/nueva-funcionalidad`
3. Commit: `git commit -m 'Agregar nueva funcionalidad'`
4. Push: `git push origin feature/nueva-funcionalidad`
5. Abrir Pull Request

---

## 🙏 Agradecimientos

- [Flutter Team](https://flutter.dev)
- [Supabase](https://supabase.com)
- [Firebase](https://firebase.google.com)
- [OpenStreetMap](https://www.openstreetmap.org)
- Comunidad de Flutter

---

## 🔮 Roadmap

- [ ] Chat en tiempo real
- [ ] Pagos integrados (Stripe/PayPal)
- [ ] Tracking GPS del técnico
- [ ] Videollamadas
- [ ] App para smartwatch
- [ ] ML para recomendaciones

---

<div align="center">

**⭐ Si te gustó el proyecto, considera darle una estrella! ⭐**

Made with ❤️ and Flutter

[⬆ Volver arriba](#-serviciosd---plataforma-de-servicios-técnicos)

</div>
