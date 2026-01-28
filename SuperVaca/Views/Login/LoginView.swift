//
//  LoginView.swift
//  SuperVaca
//
//  Created by Julio César Vaca García on 24/01/26.
//

import SwiftUI

struct LoginView: View {
    
    // MARK: - Properties
    @StateObject private var viewModel = AuthenticationViewModel()
    
    @State private var email = ""
    @State private var password = ""
    @State private var isRegistering = false
    @State private var showingPhoneLogin = false
    
    // MARK: - Body
    var body: some View {
        // GeometryReader reemplaza a UIScreen.main para obtener dimensiones seguras
        GeometryReader { geo in
            ZStack(alignment: .top) {
                
                // 1. Imagen de Cabecera
                // Se posiciona en el tope y ocupa un 35% de la altura de la pantalla
                Image("sign_in_top")
                    .resizable()
                    .scaledToFill()
                    .frame(width: geo.size.width, height: geo.size.height * 0.35)
                    .clipped() // Evita que la imagen se desborde fuera de su frame
                    .ignoresSafeArea(.all, edges: .top)
                
                // 2. Contenedor Principal (Scrollable)
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 25) {
                        
                        // Espaciador invisible para empujar el contenido debajo de la imagen
                        Spacer()
                            .frame(height: geo.size.height * 0.30)
                        
                        // --- Tarjeta de Contenido ---
                        // Usamos un fondo blanco con esquinas redondeadas superiores
                        // para crear el efecto de "tarjeta" sobre la imagen.
                        VStack(alignment: .leading, spacing: 30) {
                            
                            // Cabecera de Texto
                            VStack(alignment: .leading, spacing: 8) {
                                Text(isRegistering ? "Regístrate" : "Iniciar Sesión")
                                    .font(.system(size: 26, weight: .bold))
                                    .foregroundColor(.black)
                                
                                Text(isRegistering ? "Ingresa tus datos para continuar" : "Ingresa tu email y contraseña")
                                    .font(.system(size: 16))
                                    .foregroundColor(.lightGray)
                            }
                            .padding(.top, 10)
                            
                            // Inputs (Extraídos a componentes para limpieza)
                            VStack(spacing: 25) {
                                MinimalInput(title: "Correo Electrónico", placeholder: "ejemplo@correo.com", text: $email, keyboard: .emailAddress)
                                
                                VStack(alignment: .trailing, spacing: 10) {
                                    MinimalSecureInput(title: "Contraseña", placeholder: "••••••••", text: $password)
                                    
                                    if !isRegistering {
                                        Button("¿Olvidaste tu contraseña?") {
                                            // Acción recuperar
                                        }
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.black)
                                    }
                                }
                            }
                            
                            // Errores
                            if let error = viewModel.errorMessage {
                                Text(error)
                                    .foregroundColor(.red)
                                    .font(.caption)
                            }
                            
                            // Botón Principal
                            Button(action: handleEmailAction) {
                                ZStack {
                                    if viewModel.isLoading {
                                        ProgressView().progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    } else {
                                        Text(isRegistering ? "Registrarse" : "Ingresar")
                                            .font(.system(size: 18, weight: .bold))
                                            .foregroundColor(.white)
                                    }
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: 60)
                                .background(Color.superGreen)
                                .cornerRadius(18)
                            }
                            .disabled(viewModel.isLoading)
                            
                            // Switch Registro
                            HStack {
                                Text(isRegistering ? "¿Ya tienes cuenta?" : "¿No tienes cuenta?")
                                    .fontWeight(.semibold)
                                Button(isRegistering ? "Inicia sesión" : "Crea una ahora") {
                                    withAnimation { isRegistering.toggle() }
                                }
                                .foregroundColor(.superGreen)
                                .fontWeight(.bold)
                            }
                            .font(.system(size: 14))
                            .frame(maxWidth: .infinity)
                            
                            // Separador Social
                            HStack {
                                Rectangle().fill(Color.gray.opacity(0.3)).frame(height: 1)
                                Text("O conecta con").font(.caption).foregroundColor(.gray)
                                Rectangle().fill(Color.gray.opacity(0.3)).frame(height: 1)
                            }
                            .padding(.vertical, 10)
                            
                            // Botones Sociales (Google y Teléfono)
                            VStack(spacing: 15) {
                                SocialLoginButton(
                                    text: "Continuar con Google",
                                    imageName: "google_logo", // Asegúrate que esté en Assets
                                    bgColor: .googleBlue,
                                    isSystemImage: false
                                ) {
                                    viewModel.signInWithGoogle()
                                }
                                
                                SocialLoginButton(
                                    text: "Continuar con Teléfono",
                                    imageName: "iphone",
                                    bgColor: .phoneDark,
                                    isSystemImage: true
                                ) {
                                    showingPhoneLogin = true
                                }
                            }
                            
                            // Espacio extra al final para scroll cómodo
                            Spacer().frame(height: 50)
                            
                        }
                        .padding(.horizontal, 25)
                        .background(Color.white)
                        // Efecto visual: Curva suave en la parte superior del formulario
                        .cornerRadius(25, corners: [.topLeft, .topRight])
                        
                    } // Fin VStack Contenido
                } // Fin ScrollView
            }
            .ignoresSafeArea(.container, edges: .top)
            .background(Color.white) // Fondo base
        }
        .sheet(isPresented: $showingPhoneLogin) {
            PhoneLoginView(viewModel: viewModel)
        }
    }
    
    // MARK: - Logic Helpers
    private func handleEmailAction() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        guard !email.isEmpty, !password.isEmpty else {
            viewModel.errorMessage = "Por favor llena todos los campos."
            return
        }
        if isRegistering {
            viewModel.signUp(email: email, password: password)
        } else {
            viewModel.signIn(email: email, password: password)
        }
    }
}

// MARK: - Subcomponentes Minimalistas (Helpers)
// Extraemos estos componentes para mantener el código principal limpio

struct MinimalInput: View {
    var title: String
    var placeholder: String
    @Binding var text: String
    var keyboard: UIKeyboardType = .default
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.lightGray)
            
            TextField(placeholder, text: $text)
                .keyboardType(keyboard)
                .autocapitalization(.none)
                .font(.system(size: 18))
                .foregroundColor(.black)
            
            Divider() // La línea divisoria limpia
        }
    }
}

struct MinimalSecureInput: View {
    var title: String
    var placeholder: String
    @Binding var text: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.lightGray)
            
            SecureField(placeholder, text: $text)
                .font(.system(size: 18))
                .foregroundColor(.black)
            
            Divider()
        }
    }
}

struct SocialButtonContent: View {
    var text: String
    var image: String
    var isSystem: Bool
    
    var body: some View {
        HStack(spacing: 15) {
            if isSystem {
                Image(systemName: image)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 22, height: 22)
                    .foregroundColor(.white)
            } else {
                Image(image)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 22, height: 22)
            }
            Text(text)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)
        }
    }
}

// Botón genérico para Google/Teléfono
struct SocialLoginButton: View {
    var text: String
    var imageName: String
    var bgColor: Color
    var isSystemImage: Bool
    var action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 15) {
                if isSystemImage {
                    Image(systemName: imageName)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 24, height: 24)
                        .foregroundColor(.white)
                } else {
                    Image(imageName)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 24, height: 24)
                }
                
                Text(text)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 60)
            .background(bgColor)
            .cornerRadius(18)
        }
    }
}

// Utilidad para redondear esquinas específicas
struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView()
    }
}
