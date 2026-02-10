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
    
    // ESTADOS PARA LA RECUPERACIÓN DE CONTRASEÑA
    @State private var showResetAlert = false
    @State private var resetMessage = ""
    @State private var isResetSuccess = false
    
    // MARK: - Body
    var body: some View {
        // GeometryReader reemplaza a UIScreen.main para obtener dimensiones seguras
        GeometryReader { geo in
            ZStack(alignment: .top) {
                
                // 1. Imagen de Cabecera
                Image("sign_in_top")
                    .resizable()
                    .scaledToFill()
                    .frame(width: geo.size.width, height: geo.size.height * 0.35)
                    .clipped()
                    .ignoresSafeArea(.all, edges: .top)
                
                // 2. Contenedor Principal (Scrollable)
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 25) {
                        
                        // Espaciador invisible
                        Spacer()
                            .frame(height: geo.size.height * 0.30)
                        
                        // --- Tarjeta de Contenido ---
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
                            
                            // Inputs
                            VStack(spacing: 25) {
                                MinimalInput(title: "Correo Electrónico", placeholder: "ejemplo@correo.com", text: $email, keyboard: .emailAddress)
                                
                                VStack(alignment: .trailing, spacing: 10) {
                                    MinimalSecureInput(title: "Contraseña", placeholder: "••••••••", text: $password)
                                    
                                    if !isRegistering {
                                        // BOTÓN DE RECUPERAR CONTRASEÑA (ACTUALIZADO)
                                        Button(action: {
                                            // Llamamos a la función de reset
                                            viewModel.resetPassword(email: email) { success, message in
                                                self.isResetSuccess = success
                                                self.resetMessage = message
                                                self.showResetAlert = true
                                            }
                                        }) {
                                            Text("¿Olvidaste tu contraseña?")
                                                .font(.system(size: 14, weight: .medium))
                                                .foregroundColor(.black)
                                        }
                                    }
                                }
                            }
                            
                            // Errores Generales (Login/Registro)
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
                            
                            // Botones Sociales
                            VStack(spacing: 15) {
                                SocialLoginButton(
                                    text: "Continuar con Google",
                                    imageName: "google_logo",
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
                            
                            Spacer().frame(height: 50)
                            
                        }
                        .padding(.horizontal, 25)
                        .background(Color.white)
                        .cornerRadius(25, corners: [.topLeft, .topRight])
                        
                    }
                }
            }
            .ignoresSafeArea(.container, edges: .top)
            .background(Color.white)
        }
        .sheet(isPresented: $showingPhoneLogin) {
            PhoneLoginView(viewModel: viewModel)
        }
        // ALERTA PARA LA RECUPERACIÓN DE CONTRASEÑA [Cite: Firebase Documentation for password reset]
        .alert(isPresented: $showResetAlert) {
            Alert(
                title: Text(isResetSuccess ? "Correo Enviado" : "Aviso"),
                message: Text(resetMessage),
                dismissButton: .default(Text("Entendido"))
            )
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

// ... (El resto de tus estructuras MinimalInput, MinimalSecureInput, etc. se quedan igual)
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
            
            Divider()
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
