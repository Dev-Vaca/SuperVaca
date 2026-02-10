# 🛒 SuperVaca - iOS E-commerce App

![Swift](https://img.shields.io/badge/Swift-5.0+-orange.svg)
![Platform](https://img.shields.io/badge/iOS-15.0+-lightgrey.svg)
![Firebase](https://img.shields.io/badge/backend-Firebase-orange)

**SuperVaca** es una aplicación nativa de iOS desarrollada en **SwiftUI** diseñada para facilitar la compra de productos de supermercado a domicilio. El proyecto implementa una arquitectura moderna, gestión de estados en tiempo real y servicios en la nube para ofrecer una experiencia de usuario fluida y segura.

---

## 📱 Capturas de Pantalla (Screenshots)

| Login & Auth | Home / Catálogo | Explorador | Detalle de Producto |
|:---:|:---:|:---:|:---:|
| ![Login View](https://github.com/Dev-Vaca/SuperVaca/blob/main/login.png) | ![Home View](https://github.com/Dev-Vaca/SuperVaca/blob/main/home.png) | ![Explore View]([./Screenshots/explore.png](https://github.com/Dev-Vaca/SuperVaca/blob/main/explorador.png)) | ![Detail View]([./Screenshots/detail.png](https://github.com/Dev-Vaca/SuperVaca/blob/main/detail.png)) |
| *Autenticación Segura* | *Novedades y Ofertas* | *Búsqueda por Categorías* | *Info Nutricional y Precio* |

| Favoritos | Carrito de Compras | Mi Cuenta |
|:---:|:---:|:---:|
| ![Favorites View]([./Screenshots/favorites.png](https://github.com/Dev-Vaca/SuperVaca/blob/main/fav.png)) | ![Cart View]([./Screenshots/cart.png](https://github.com/Dev-Vaca/SuperVaca/blob/main/car.png)) | ![Account View]([./Screenshots/account.png](https://github.com/Dev-Vaca/SuperVaca/blob/main/cuenta.png)) |
| *Lista de Deseos* | *Gestión de Pedidos* | *Perfil y Configuración* |


---

## ✨ Características Principales

* **Autenticación Robusta:**
    * Inicio de sesión con Correo/Contraseña.
    * Integración social con **Google Sign-In**.
    * Autenticación biométrica/SMS mediante **Phone Auth** de Firebase.
* **Gestión de Productos:**
    * Catálogo dinámico dividido por categorías (Carnes, Frutas, Lácteos, Panadería, Verduras).
    * Sistema de **Caché de Imágenes** optimizado para reducir consumo de datos y memoria.
* **Experiencia de Usuario (UX):**
    * **Modo Offline:** Detección de conexión a internet con bloqueo de UI y notificaciones visuales (`NoInternetView`).
    * Animaciones fluidas y transiciones entre estados.
* **E-commerce:**
    * Carrito de compras persistente.
    * Gestión de Favoritos.
    * Historial de pedidos.
* **Panel de Administrador:** Dashboard dedicado para la gestión del negocio.

---

## 🛠 Arquitectura y Tecnologías

El proyecto sigue el patrón de diseño **MVVM (Model-View-ViewModel)** para asegurar una separación clara de responsabilidades y un código testearle.

### Stack Tecnológico
* **Lenguaje:** Swift 5.
* **UI Framework:** SwiftUI.
* **Concurrencia:** Swift Concurrency (`async/await`) y `Combine`.
* **Backend as a Service:** Firebase (Auth, Firestore, Storage).
* **Dependencias:** GoogleSignIn, FirebaseSDK.

### Estructura del Proyecto

```text
SuperVaca/
├── App/
│   ├── SuperVacaApp.swift       # Punto de entrada y configuración de Firebase
│   └── AppDelegate.swift        # Manejo de notificaciones y callbacks de Auth
├── Models/
│   ├── Product.swift            # Modelo de datos
│   ├── User.swift               
│   └── Order.swift
├── ViewModels/                  # Lógica de Negocio
│   ├── AuthenticationViewModel.swift  # Gestión de sesión (Login, Sign Up, Google)
│   ├── ProductManager.swift           # Fetching y caché de productos
│   ├── CartManager.swift              # Lógica del carrito
│   └── NetworkMonitor.swift           # Monitoreo de conectividad
├── Views/
│   ├── Login/                   # Vistas de autenticación
│   ├── Principal/               # Home, Explorar, Cuenta
│   └── Common/                  # Componentes reutilizables (NoInternetView, etc.)
└── Utils/
    └── ImageCache.swift         # Gestor de descarga de imágenes
```

🧩 Detalles de Implementación Interesantes
Gestión de Conectividad

La app implementa un monitor de red global. Si se pierde la conexión, la interfaz se desenfoca y bloquea las interacciones para evitar errores de consistencia de datos.

Swift
// Ejemplo en SuperVacaApp.swift
.disabled(!networkMonitor.isConnected)
.blur(radius: networkMonitor.isConnected ? 0 : 5)
Optimización de Imágenes

Para evitar problemas de memoria (especialmente con catálogos grandes), se implementó un URLCache personalizado en el inicializador de la App con límites de memoria y disco.

👤 Autor
Julio César Vaca García

Contacto: jvaca1309@gmail.com
