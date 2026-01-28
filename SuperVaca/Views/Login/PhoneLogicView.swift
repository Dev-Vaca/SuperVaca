//
//  PhoneLoginView.swift
//  SuperVaca
//
//  Created by Julio César Vaca García on 24/01/26.
//

import SwiftUI
// Ya no necesitamos importar librerías externas que fallan

struct PhoneLoginView: View {
    
    // MARK: - Properties
    @ObservedObject var viewModel: AuthenticationViewModel
    @Environment(\.presentationMode) var presentationMode
    
    // Estados locales
    @State private var phoneNumber = ""
    @State private var verificationCode = ""
    @State private var isCodeSent = false
    
    // Datos del País (Por defecto México)
    @State private var countryCode = "+52"
    @State private var countryFlag = "🇲🇽"
    
    // Lista simple de países comunes (Puedes agregar más)
    let countries = [
        ("🇲🇽", "+52", "México"),
        ("🇺🇸", "+1", "USA"),
        ("🇨🇴", "+57", "Colombia"),
        ("🇪🇸", "+34", "España"),
        ("🇦🇷", "+54", "Argentina"),
        ("🇨🇱", "+56", "Chile"),
        ("🇵🇪", "+51", "Perú")
    ]
    
    // MARK: - Body
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                
                // 1. Cabecera con Icono y Texto
                VStack(spacing: 15) {
                    Image(systemName: isCodeSent ? "message.badge.filled.fill" : "iphone.gen3")
                        .font(.system(size: 60))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.superGreen, .superGreen.opacity(0.7)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .padding(.top, 20)
                    
                    VStack(spacing: 5) {
                        Text(isCodeSent ? "Verifica tu Identidad" : "Inicia con tu Celular")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.primary)
                        
                        Text(isCodeSent ? "Ingresa el código que enviamos por SMS" : "Te enviaremos un código de seguridad")
                            .font(.system(size: 15))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                }
                
                // 2. Formulario Principal
                VStack(spacing: 25) {
                    
                    if !isCodeSent {
                        // --- PASO 1: CAMPO DE TELÉFONO MANUAL (ROBUSTO) ---
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Número de Teléfono")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.gray)
                                .padding(.leading, 5)
                            
                            HStack(spacing: 15) {
                                // A. Selector de País (Menu Nativo)
                                Menu {
                                    ForEach(countries, id: \.1) { country in
                                        Button {
                                            countryFlag = country.0
                                            countryCode = country.1
                                        } label: {
                                            Text("\(country.0) \(country.2) \(country.1)")
                                        }
                                    }
                                } label: {
                                    HStack(spacing: 5) {
                                        Text(countryFlag)
                                            .font(.system(size: 24))
                                        Text(countryCode)
                                            .font(.system(size: 18, weight: .bold))
                                            .foregroundColor(.primary)
                                        Image(systemName: "chevron.down")
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                    }
                                    .padding(.vertical, 12)
                                    .padding(.horizontal, 12)
                                    .background(Color(.systemGray6))
                                    .cornerRadius(12)
                                }
                                
                                // B. Campo de Texto del Número
                                TextField("312 123 4567", text: $phoneNumber)
                                    .keyboardType(.numberPad)
                                    .font(.system(size: 20, weight: .semibold))
                                    .padding()
                                    .background(Color(.systemGray6))
                                    .cornerRadius(12)
                            }
                        }
                        
                    } else {
                        // --- PASO 2: CAMPO DE CÓDIGO SMS ---
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Código de Verificación")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.gray)
                                .padding(.leading, 5)
                            
                            HStack {
                                Image(systemName: "lock.fill")
                                    .foregroundColor(.gray)
                                    .padding(.leading, 15)
                                
                                TextField("123456", text: $verificationCode)
                                    .keyboardType(.numberPad)
                                    .font(.system(size: 24, weight: .bold, design: .monospaced))
                                    .padding(.vertical, 15)
                            }
                            .background(Color(.systemGray6))
                            .cornerRadius(16)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.superGreen.opacity(0.5), lineWidth: 1)
                            )
                        }
                    }
                    
                    // Manejo de Errores Visuales
                    if let error = viewModel.errorMessage {
                        HStack(alignment: .top) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.red)
                            Text(error)
                                .font(.caption)
                                .foregroundColor(.red)
                                .multilineTextAlignment(.leading)
                        }
                        .padding(.horizontal)
                    }
                    
                    // Botón de Acción
                    Button(action: handleMainAction) {
                        ZStack {
                            if viewModel.isLoading {
                                ProgressView().progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                HStack {
                                    Text(isCodeSent ? "Verificar Código" : "Enviar SMS")
                                        .fontWeight(.bold)
                                        .font(.title3)
                                    Image(systemName: "arrow.right")
                                        .font(.caption.weight(.bold))
                                }
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 60)
                        .background(isButtonDisabled ? Color.gray : Color.superGreen)
                        .foregroundColor(.white)
                        .cornerRadius(18)
                        .shadow(color: isButtonDisabled ? .clear : Color.superGreen.opacity(0.4), radius: 10, x: 0, y: 5)
                    }
                    .disabled(isButtonDisabled)
                }
                .padding(.horizontal, 25)
                
                Spacer()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { presentationMode.wrappedValue.dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 30))
                            .foregroundColor(.gray.opacity(0.3))
                    }
                }
            }
        }
    }
    
    // MARK: - Logic Helpers
    
    private var isButtonDisabled: Bool {
        if viewModel.isLoading { return true }
        if isCodeSent {
            return verificationCode.count < 6
        } else {
            return phoneNumber.count < 10 // Validación básica
        }
    }
    
    private func handleMainAction() {
        // Ocultar teclado
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        
        if isCodeSent {
            // Paso 2: Finalizar Login
            viewModel.signInWithSMSCode(verificationCode: verificationCode)
        } else {
            // Paso 1: Enviar SMS
            // AQUÍ ESTÁ EL TRUCO: Concatenamos manualmente el código de país.
            // Esto garantiza que Firebase reciba "+52313..." y no solo "313..."
            
            // Limpiamos el número de espacios o guiones por si acaso
            let cleanNumber = phoneNumber.replacingOccurrences(of: " ", with: "").replacingOccurrences(of: "-", with: "")
            let fullPhoneNumber = "\(countryCode)\(cleanNumber)"
            
            print("Enviando SMS a: \(fullPhoneNumber)") // Debug en consola
            
            viewModel.verifyPhoneNumber(phoneNumber: fullPhoneNumber) { success in
                if success {
                    withAnimation { isCodeSent = true }
                }
            }
        }
    }
}

// Preview
struct PhoneLoginView_Previews: PreviewProvider {
    static var previews: some View {
        PhoneLoginView(viewModel: AuthenticationViewModel())
    }
}
