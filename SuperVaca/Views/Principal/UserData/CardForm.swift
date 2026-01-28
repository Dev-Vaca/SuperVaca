//
//  CardFormView.swift
//  SuperVaca
//
//  Formulario para agregar una tarjeta (Simulación segura).
//

import SwiftUI

struct CardFormView: View {
    @Environment(\.presentationMode) var presentationMode
    
    @State private var holderName = ""
    @State private var cardNumber = ""
    @State private var expiry = ""
    @State private var cvv = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                
                // VISUALIZACIÓN DE LA TARJETA (Tipo Wallet)
                ZStack(alignment: .bottomLeading) {
                    LinearGradient(gradient: Gradient(colors: [Color.blue, Color.purple]), startPoint: .topLeading, endPoint: .bottomTrailing)
                        .cornerRadius(15)
                        .shadow(radius: 5)
                    
                    VStack(alignment: .leading, spacing: 15) {
                        HStack {
                            Image(systemName: "checkmark.shield.fill") // Simula chip
                                .font(.title)
                                .foregroundColor(.white.opacity(0.8))
                            Spacer()
                            Text(detectBrand())
                                .font(.headline.italic())
                                .foregroundColor(.white)
                        }
                        
                        Text(formatCardNumber(cardNumber))
                            .font(.system(size: 22, weight: .bold, design: .monospaced))
                            .foregroundColor(.white)
                        
                        HStack {
                            VStack(alignment: .leading) {
                                Text("TITULAR")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.7))
                                Text(holderName.isEmpty ? "NOMBRE APELLIDO" : holderName.uppercased())
                                    .font(.headline)
                                    .foregroundColor(.white)
                            }
                            Spacer()
                            VStack(alignment: .leading) {
                                Text("EXPIRA")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.7))
                                Text(expiry.isEmpty ? "MM/YY" : expiry)
                                    .font(.headline)
                                    .foregroundColor(.white)
                            }
                        }
                    }
                    .padding(20)
                }
                .frame(height: 200)
                .padding()
                
                // FORMULARIO
                Form {
                    Section(header: Text("Datos de la Tarjeta")) {
                        TextField("Nombre del Titular", text: $holderName)
                        
                        TextField("Número de Tarjeta", text: $cardNumber)
                            .keyboardType(.numberPad)
                            .onChange(of: cardNumber) { _ in
                                if cardNumber.count > 16 { cardNumber = String(cardNumber.prefix(16)) }
                            }
                        
                        HStack {
                            TextField("MM/YY", text: $expiry)
                                .keyboardType(.numbersAndPunctuation)
                                .onChange(of: expiry) { _ in
                                    if expiry.count > 5 { expiry = String(expiry.prefix(5)) }
                                }
                            
                            Divider()
                            
                            TextField("CVV", text: $cvv)
                                .keyboardType(.numberPad)
                                .onChange(of: cvv) { _ in
                                    if cvv.count > 3 { cvv = String(cvv.prefix(3)) }
                                }
                        }
                    }
                    
                    Button(action: saveCard) {
                        Text("Guardar Tarjeta")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(isFormValid ? Color.superGreen : Color.gray)
                            .cornerRadius(10)
                    }
                    .disabled(!isFormValid)
                    .listRowBackground(Color.clear)
                }
            }
            .navigationTitle("Nueva Tarjeta")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { presentationMode.wrappedValue.dismiss() }
                }
            }
        }
    }
    
    var isFormValid: Bool {
        !holderName.isEmpty && cardNumber.count == 16 && expiry.count == 5 && cvv.count == 3
    }
    
    func detectBrand() -> String {
        if cardNumber.hasPrefix("4") { return "VISA" }
        if cardNumber.hasPrefix("5") { return "MASTERCARD" }
        if cardNumber.hasPrefix("34") || cardNumber.hasPrefix("37") { return "AMEX" }
        return "TARJETA"
    }
    
    // Formato visual para que se vea bonito (**** **** **** 1234)
    func formatCardNumber(_ number: String) -> String {
        var formatted = ""
        for (index, char) in number.enumerated() {
            if index > 0 && index % 4 == 0 {
                formatted += " "
            }
            formatted.append(char)
        }
        return formatted.isEmpty ? "0000 0000 0000 0000" : formatted
    }
    
    func saveCard() {
        // AQUÍ ESTÁ LA SEGURIDAD: Solo guardamos los últimos 4 dígitos
        let last4Digits = String(cardNumber.suffix(4))
        
        let newCard = PaymentCard(
            cardHolder: holderName,
            last4: last4Digits,
            brand: detectBrand(),
            expiryDate: expiry
        )
        
        UserManager.shared.saveCard(newCard)
        presentationMode.wrappedValue.dismiss()
    }
}
