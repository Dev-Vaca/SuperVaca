//
//  SuperVacaApp.swift
//  SuperVaca
//
//  Created by Julio César Vaca García on 24/01/26.
//

import SwiftUI
import FirebaseCore
import FirebaseAuth
import GoogleSignIn

// MARK: - AppDelegate
class AppDelegate: NSObject, UIApplicationDelegate {
    
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        
        FirebaseApp.configure()
        
        // Configurar notificaciones remotas para autenticación telefónica
        application.registerForRemoteNotifications()
        
        return true
    }
    
    // 1. Manejo de URLs (Para Google Sign-In)
    func application(_ app: UIApplication,
                     open url: URL,
                     options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
        return GIDSignIn.sharedInstance.handle(url)
    }
    
    // 2. Registro de Notificaciones (Para Phone Auth)
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        Auth.auth().setAPNSToken(deviceToken, type: .prod)
    }
    
    // 3. Recepción de Notificaciones
    func application(_ application: UIApplication,
                     didReceiveRemoteNotification userInfo: [AnyHashable : Any],
                     fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        
        if Auth.auth().canHandleNotification(userInfo) {
            completionHandler(.noData)
            return
        }
        
        completionHandler(.newData)
    }
}

@main
struct SupermarketApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    // Inyectamos el ViewModel de Autenticación
    @StateObject var authenticationViewModel = AuthenticationViewModel()
    
    // Inyectamos el Monitor de Red (Nuevo)
    @StateObject var networkMonitor = NetworkMonitor()
    
    // Configuración Inicial (Caché)
    init() {
        // LIMITAR CACHÉ DE IMÁGENES (Para solucionar el problema de los 800MB)
        // Memoria RAM: 20 MB, Disco: 100 MB.
        URLCache.shared = URLCache(memoryCapacity: 20 * 1024 * 1024,
                                   diskCapacity: 100 * 1024 * 1024,
                                   diskPath: "supervaca_cache")
    }
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                // -----------------------------------------------------------
                // CONTENIDO PRINCIPAL (Protegido por ZStack)
                // -----------------------------------------------------------
                Group {
                    if let user = authenticationViewModel.user {
                        // SI HAY USUARIO: Vamos a la App Principal
                        MainTabView()
                            .transition(.opacity)
                            .onAppear {
                                // AQUÍ ESTÁ LA CLAVE 🔑
                                // Iniciamos TODOS los servicios de Firebase
                                print("🟢 Usuario detectado (UID: \(user.uid)). Sincronizando datos...")
                                
                                // 1. Cargar Favoritos
                                FavoritesManager.shared.fetchFavorites()
                                
                                // 2. Cargar Carrito
                                CartManager.shared.fetchCart()
                                
                                // 3. Cargar catalogo de productos
                                Task {
                                    await ProductManager.shared.loadProducts()
                                }
                                
                                UserManager.shared.fetchUserProfile()
                            }
                    } else {
                        // SI NO HAY USUARIO: Vamos al Login
                        LoginView()
                            .onAppear {
                                // Por seguridad, limpiamos datos locales al cerrar sesión
                                FavoritesManager.shared.favoriteProductIDs = []
                                CartManager.shared.cartItems = [] // Limpiamos carrito
                            }
                    }
                }
                .disabled(!networkMonitor.isConnected) // Bloquea toques si no hay red
                .blur(radius: networkMonitor.isConnected ? 0 : 5) // Desenfoca el fondo si no hay red
                
                // -----------------------------------------------------------
                // CAPA DE PROTECCIÓN: NO INTERNET
                // -----------------------------------------------------------
                if !networkMonitor.isConnected {
                    NoInternetView()
                        .transition(.opacity.animation(.easeInOut))
                        .zIndex(1) // Asegura que esté siempre encima
                }
            }
            .animation(.easeInOut, value: networkMonitor.isConnected)
            // Inyectamos el monitor por si alguna vista hija quiere saber el estado
            .environmentObject(networkMonitor)
        }
    }
}
