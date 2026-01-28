//
//  AuthenticationViewModel.swift
//  SuperVaca
//
//  Created by Julio César Vaca García on 24/01/26.
//

import Foundation
import FirebaseAuth
import Combine
import GoogleSignIn
import FirebaseCore

// MARK: - AuthenticationViewModel
// Gestiona el estado de autenticación y la comunicación con el servicio de identidad (Firebase).
// Implementa ObservableObject para permitir que la vista reaccione a cambios de estado.
final class AuthenticationViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    // Almacena el usuario autenticado actual. Si es nil, el usuario no está logueado.
    @Published var user: User?
    
    // Controla si hay una operación de red en curso para mostrar indicadores de carga en la UI.
    @Published var isLoading: Bool = false
    
    // Almacena mensajes de error para ser presentados al usuario en caso de fallos.
    @Published var errorMessage: String?
    
    // Almacena la suscripción al listener de autenticación para gestionar su ciclo de vida.
    private var handle: AuthStateDidChangeListenerHandle?
    
    // MARK: - Initialization
    
    init() {
        registerAuthStateHandler()
    }
    
    deinit {
        // Es crucial remover el listener para evitar fugas de memoria cuando la clase es destruida.
        if let handle = handle {
            Auth.auth().removeStateDidChangeListener(handle)
        }
    }
    
    // MARK: - Private Methods
    
    // Establece un observador sobre el objeto Auth de Firebase.
    // Esto asegura que la UI se actualice automáticamente si la sesión cambia externamente.
    private func registerAuthStateHandler() {
        handle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            // Se utiliza [weak self] para evitar ciclos de retención (retain cycles).
            DispatchQueue.main.async {
                self?.user = user
                self?.isLoading = false
            }
        }
    }
    
    // MARK: - Public Methods (Auth Actions)
    
    // Inicia sesión utilizando correo electrónico y contraseña.
    // - Parameters:
    //   - email: Correo del usuario.
    //   - password: Contraseña del usuario.
    func signIn(email: String, password: String) {
        isLoading = true
        errorMessage = nil
        
        Auth.auth().signIn(withEmail: email, password: password) { [weak self] result, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                if let error = error {
                    // Mapeo simple del error. En producción, esto debería localizarse según el código de error.
                    self?.errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    // Crea un nuevo usuario en el sistema.
    func signUp(email: String, password: String) {
        isLoading = true
        errorMessage = nil
        
        Auth.auth().createUser(withEmail: email, password: password) { [weak self] result, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                if let error = error {
                    self?.errorMessage = error.localizedDescription
                }
                // Nota: Firebase loguea automáticamente al usuario tras un registro exitoso.
            }
        }
    }
    
    // Cierra la sesión actual del usuario.
    func signOut() {
        do {
            try Auth.auth().signOut()
        } catch {
            errorMessage = "Error al cerrar sesión: \(error.localizedDescription)"
        }
    }
    
    // MARK: - Social Auth Placeholders
    // Estos métodos requieren configuración adicional en el Info.plist y delegados de Scene.
    
    func signInWithGoogle() {
            isLoading = true
            
            // 1. Obtenemos el controlador de vista raíz para presentar el modal de Google.
            // En una arquitectura MVVM estricta, esto debería inyectarse, pero usamos la escena activa por pragmatismo.
            guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                  let rootViewController = windowScene.windows.first?.rootViewController else {
                print("Error: No se pudo obtener el rootViewController")
                isLoading = false
                return
            }
            
            // 2. Iniciamos el flujo de Google Sign-In.
            GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController) { [weak self] result, error in
                guard let self = self else { return }
                
                if let error = error {
                    self.errorMessage = "Error en Google Sign-In: \(error.localizedDescription)"
                    self.isLoading = false
                    return
                }
                
                guard let user = result?.user,
                      let idToken = user.idToken?.tokenString else {
                    self.errorMessage = "Error: No se pudo obtener el token de ID de Google."
                    self.isLoading = false
                    return
                }
                
                // Obtenemos el access token (necesario para la credencial)
                let accessToken = user.accessToken.tokenString
                
                // 3. Intercambio de credenciales.
                // Convertimos los tokens de Google en una credencial que Firebase entiende.
                let credential = GoogleAuthProvider.credential(withIDToken: idToken,
                                                               accessToken: accessToken)
                
                // 4. Autenticación en Firebase.
                Auth.auth().signIn(with: credential) { authResult, error in
                    DispatchQueue.main.async {
                        self.isLoading = false
                        if let error = error {
                            self.errorMessage = "Error al autenticar en Firebase: \(error.localizedDescription)"
                            return
                        }
                        
                        // Éxito. El listener 'addStateDidChangeListener' en el init detectará el cambio
                        // y actualizará la variable 'user' automáticamente.
                        print("Usuario logueado con Google exitosamente: \(authResult?.user.uid ?? "")")
                    }
                }
            }
        }
    
    
    func signInWithFacebook() {
        // TODO: Implementar Facebook Login SDK logic.
        print("Iniciando flujo de Facebook Login")
    }
}

extension AuthenticationViewModel {
    
    // MARK: - Phone Auth Methods
    
    /// Paso 1: Envía el SMS de verificación al número proporcionado.
    /// - Parameters:
    ///   - phoneNumber: El número en formato internacional (ej: +521234567890).
    ///   - completion: Devuelve `true` si el SMS se envió correctamente.
    func verifyPhoneNumber(phoneNumber: String, completion: @escaping (Bool) -> Void) {
        isLoading = true
        errorMessage = nil
        
        // NOTA PARA DESARROLLO:
        // En el simulador, Firebase NO envía SMS reales.
        // Debes configurar un número de prueba en la consola de Firebase
        // (Authentication -> Sign-in method -> Phone -> "Números de teléfono de prueba").
        // Usa ese número y código fijo aquí.
        // Si usas un dispositivo real, Firebase usará reCAPTCHA invisible o notificaciones push para verificar.
        
        #if targetEnvironment(simulator)
        Auth.auth().settings?.isAppVerificationDisabledForTesting = true
        #endif
        
        PhoneAuthProvider.provider().verifyPhoneNumber(phoneNumber, uiDelegate: nil) { [weak self] verificationID, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                if let error = error {
                    // Manejo de errores comunes (ej: formato de número inválido)
                    self?.errorMessage = "Error al enviar SMS: \(error.localizedDescription)"
                    completion(false)
                    return
                }
                
                // ÉXITO: Firebase nos devuelve un ID de verificación.
                // Es CRÍTICO guardar este ID. Lo guardamos en UserDefaults por si la app se cierra
                // mientras el usuario busca el código en sus mensajes.
                if let verificationID = verificationID {
                    UserDefaults.standard.set(verificationID, forKey: "authVerificationID")
                    completion(true) // Notificamos a la vista que puede mostrar el campo del código.
                }
            }
        }
    }
    
    /// Paso 2: Finaliza el login usando el código que el usuario recibió por SMS.
    /// - Parameter verificationCode: El código de 6 dígitos ingresado por el usuario.
    func signInWithSMSCode(verificationCode: String) {
        isLoading = true
        errorMessage = nil
        
        // 1. Recuperamos el ID de verificación que guardamos en el paso 1.
        guard let verificationID = UserDefaults.standard.string(forKey: "authVerificationID") else {
            errorMessage = "Error interno: No se encontró el ID de verificación. Intenta enviar el SMS de nuevo."
            isLoading = false
            return
        }
        
        // 2. Creamos la credencial combinando el ID y el código del usuario.
        let credential = PhoneAuthProvider.provider().credential(
            withVerificationID: verificationID,
            verificationCode: verificationCode
        )
        
        // 3. Autenticamos en Firebase.
        Auth.auth().signIn(with: credential) { [weak self] authResult, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                if let error = error {
                    self?.errorMessage = "Código incorrecto o error de validación: \(error.localizedDescription)"
                    return
                }
                
                // Si el login es exitoso, el listener principal en el 'init' del ViewModel
                // detectará el cambio en 'Auth.auth()' y actualizará la variable 'user' automáticamente,
                // cerrando esta vista y mostrando la pantalla principal.
                print("Login con teléfono exitoso para: \(authResult?.user.uid ?? "N/A")")
                // Limpiamos el ID usado
                 UserDefaults.standard.removeObject(forKey: "authVerificationID")
            }
        }
    }
}
