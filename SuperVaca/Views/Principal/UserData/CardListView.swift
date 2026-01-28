//
//  PaymentMethodsView.swift
//  SuperVaca
//
//  Lista de tarjetas guardadas.
//  Diseño "Wallet".
//

import SwiftUI

struct PaymentMethodsView: View {
    @ObservedObject var userManager = UserManager.shared
    @State private var showAddForm = false
    
    var body: some View {
        ZStack {
            // Fondo sutil
            Color(.systemGroupedBackground).ignoresSafeArea()
            
            if userManager.cards.isEmpty {
                emptyStateView
            } else {
                List {
                    ForEach(userManager.cards) { card in
                        CreditCardRow(card: card)
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                            .padding(.bottom, 10)
                            .transition(.scale.combined(with: .opacity))
                    }
                    .onDelete { indexSet in
                        indexSet.forEach { index in
                            let card = userManager.cards[index]
                            withAnimation {
                                userManager.deleteCard(card)
                            }
                        }
                    }
                }
                .listStyle(.plain)
                .padding(.top, 10)
                .animation(.spring(), value: userManager.cards)
            }
        }
        .navigationTitle("Métodos de Pago")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showAddForm = true }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.superGreen)
                }
            }
        }
        .sheet(isPresented: $showAddForm) {
            CardFormView()
        }
    }
    
    var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "creditcard.and.123")
                .font(.system(size: 70))
                .foregroundColor(.gray.opacity(0.4))
                .padding(.bottom, 10)
            Text("Tu billetera está vacía")
                .font(.title3.bold())
                .foregroundColor(.gray)
            Text("Agrega una tarjeta para realizar tus pedidos más rápido.")
                .font(.subheadline)
                .foregroundColor(.gray.opacity(0.8))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            Button(action: { showAddForm = true }) {
                Text("Agregar Tarjeta")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding().padding(.horizontal, 20)
                    .background(Color.superGreen)
                    .cornerRadius(10)
                    .shadow(radius: 5)
            }
            .padding(.top, 20)
        }
        .transition(.opacity)
    }
}

// MARK: - Diseño de la Tarjeta (Fila)
struct CreditCardRow: View {
    let card: PaymentCard
    @State private var isPressed = false
    
    var body: some View {
        ZStack(alignment: .bottomLeading) {
            // 1. FONDO DEGRADADO
            LinearGradient(
                gradient: cardGradient(brand: card.brand),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .cornerRadius(16)
            .shadow(color: .black.opacity(isPressed ? 0.3 : 0.15), radius: isPressed ? 12 : 8, x: 0, y: isPressed ? 6 : 4)
            
            // 2. CONTENIDO
            VStack(alignment: .leading, spacing: 20) {
                HStack {
                    Image(systemName: "simcard.fill")
                        .font(.title2)
                        // Si es Amex Gold, el chip se ve mejor un poco más oscuro
                        .foregroundColor(card.brand == "AMEX" ? .black.opacity(0.5) : .white.opacity(0.8))
                        .rotationEffect(.degrees(90))
                    Spacer()
                    brandLogoView(brand: card.brand)
                }
                
                // Número
                Text("•••• •••• •••• \(card.last4)")
                    .font(.system(size: 20, weight: .bold, design: .monospaced))
                    // Texto negro para Amex Gold, blanco para las demás
                    .foregroundColor(card.brand == "AMEX" ? .black.opacity(0.8) : .white)
                    .shadow(color: .black.opacity(0.1), radius: 1, x: 0, y: 1)
                
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("TITULAR")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundColor(card.brand == "AMEX" ? .black.opacity(0.5) : .white.opacity(0.6))
                        Text(card.cardHolder.uppercased())
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(card.brand == "AMEX" ? .black.opacity(0.8) : .white)
                    }
                    Spacer()
                    VStack(alignment: .leading, spacing: 2) {
                        Text("VENCE")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundColor(card.brand == "AMEX" ? .black.opacity(0.5) : .white.opacity(0.6))
                        Text(card.expiryDate)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(card.brand == "AMEX" ? .black.opacity(0.8) : .white)
                    }
                }
            }
            .padding(20)
        }
        .frame(height: 180)
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
        .onLongPressGesture(minimumDuration: 0.1, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
    }
    
    // LOGICA DE LOGOS
    @ViewBuilder
    func brandLogoView(brand: String) -> some View {
        let brandClean = brand.lowercased()
        
        if brandClean.contains("visa") {
            Image("visa")
                .resizable().scaledToFit()
                .frame(width: 70, height: 45)
                .colorInvert().brightness(1) // Blanco puro
            
        } else if brandClean.contains("master") {
            Image("mastercard")
                .resizable().scaledToFit()
                .frame(width: 60, height: 40)
            
        } else if brandClean.contains("amex") {
            Image("amex")
                .resizable().scaledToFit()
                // AUMENTADO: Logo Amex más grande
                .frame(width: 80, height: 50)
            
        } else {
            Text(brand.uppercased())
                .font(.system(size: 16, weight: .bold, design: .serif))
                .italic()
                .foregroundColor(.white)
        }
    }
    
    // LOGICA DE COLORES (Nueva paleta)
    func cardGradient(brand: String) -> Gradient {
        let brandClean = brand.lowercased()
        
        if brandClean.contains("visa") {
            // Azul Visa Clásico
            return Gradient(colors: [Color(hexString: "1a1f71"), Color(hexString: "0057b8")])
            
        } else if brandClean.contains("master") {
            // Gris Oscuro / Negro Titanium
            return Gradient(colors: [Color(hexString: "222222"), Color(hexString: "444444")])
            
        } else if brandClean.contains("amex") {
            return Gradient(colors: [Color(hexString: "D9A32D"), Color(hexString: "FCEEB5")])
            
        } else {
            // Genérico
            return Gradient(colors: [Color.gray, Color.black])
        }
    }
}

// Extension Hex (Necesaria si no la tienes en otro lado)
extension Color {
    init(hexString: String) {
        let hexInput = hexString.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hexInput).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hexInput.count {
        case 3: (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default: (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(.sRGB, red: Double(r) / 255, green: Double(g) / 255, blue: Double(b) / 255, opacity: Double(a) / 255)
    }
}
