//
//  CheckoutView.swift
//  SuperVaca
//
//  Pantalla final de pago.
//  CORREGIDO: Overlay de éxito visible.
//

import SwiftUI
import StripePaymentSheet

struct CheckoutView: View {
    @Environment(\.presentationMode) var presentationMode
    
    // Managers
    @ObservedObject var cartManager = CartManager.shared
    @ObservedObject var userManager = UserManager.shared
    @ObservedObject var orderManager = OrderManager.shared
    @StateObject var paymentManager = PaymentManager.shared
    
    // Selecciones
    @State private var selectedAddress: Address?
    
    // Estados de UI
    @State private var showSuccess = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showStripeSheet = false
    
    // Cálculo del total
    var subtotal: Double {
        var total: Double = 0
        for item in cartManager.cartItems {
            if let product = ProductManager.shared.getProduct(byId: item.id) {
                total += product.price * item.quantity
            }
        }
        return total
    }
    
    var body: some View {
        ZStack {
            // CONTENIDO PRINCIPAL
            VStack(spacing: 0) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 25) {
                        
                        // 1. DIRECCIÓN
                        VStack(alignment: .leading, spacing: 15) {
                            Text("¿DÓNDE ENTREGAMOS?")
                                .font(.caption).bold().foregroundColor(.gray)
                                .padding(.horizontal)
                            
                            if userManager.addresses.isEmpty {
                                NavigationLink(destination: AddressFormView()) {
                                    EmptySelectionBox(icon: "map", text: "Agregar Dirección")
                                }
                                .padding(.horizontal)
                            } else {
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 15) {
                                        ForEach(userManager.addresses) { address in
                                            AddressSelectionCard(address: address, isSelected: selectedAddress?.id == address.id)
                                                .onTapGesture { withAnimation { selectedAddress = address } }
                                        }
                                    }
                                    .padding(.horizontal)
                                }
                            }
                        }
                        
                        // 2. MÉTODO DE PAGO
                        VStack(alignment: .leading, spacing: 15) {
                            Text("MÉTODO DE PAGO")
                                .font(.caption).bold().foregroundColor(.gray)
                                .padding(.horizontal)
                            
                            HStack {
                                Image(systemName: "creditcard.fill").font(.title2).foregroundColor(.blue)
                                VStack(alignment: .leading) {
                                    Text("Tarjeta Bancaria").font(.headline)
                                    Text("Procesado seguro por Stripe").font(.caption).foregroundColor(.gray)
                                }
                                Spacer()
                                Image(systemName: "lock.shield.fill").foregroundColor(.superGreen)
                            }
                            .padding()
                            .background(Color.white)
                            .cornerRadius(12)
                            .padding(.horizontal)
                        }
                        
                        // 3. RESUMEN
                        VStack(alignment: .leading, spacing: 15) {
                            Text("RESUMEN").font(.caption).bold().foregroundColor(.gray).padding(.horizontal)
                            VStack(spacing: 12) {
                                SummaryRow(title: "Subtotal", value: "$\(String(format: "%.2f", subtotal))")
                                SummaryRow(title: "Envío", value: "Gratis", isHighlight: true)
                                Divider()
                                HStack {
                                    Text("Total a Pagar").font(.headline)
                                    Spacer()
                                    Text("$\(String(format: "%.2f", subtotal))").font(.title2.bold())
                                }
                            }
                            .padding()
                            .background(Color.white)
                            .cornerRadius(12)
                            .padding(.horizontal)
                        }
                    }
                    .padding(.vertical, 20)
                }
                
                // 4. BOTÓN PAGAR
                VStack {
                    Button(action: startStripePayment) {
                        HStack {
                            if paymentManager.isProcessing {
                                ProgressView().progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Text("Pagar $\(String(format: "%.2f", subtotal))").font(.headline.bold())
                                Image(systemName: "checkmark.seal.fill")
                            }
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(canPay ? Color.superGreen : Color.gray)
                        .cornerRadius(15)
                        .shadow(color: canPay ? Color.superGreen.opacity(0.4) : Color.clear, radius: 10, y: 5)
                    }
                    .disabled(!canPay || paymentManager.isProcessing)
                }
                .padding()
                .background(Color.white.ignoresSafeArea(edges: .bottom))
            }
            .background(Color(.systemGroupedBackground))
            .blur(radius: showSuccess ? 5 : 0)
            
            // SPINNER DE CARGA
            if paymentManager.isProcessing {
                ZStack {
                    Color.black.opacity(0.3).ignoresSafeArea()
                    ProgressView("Procesando...")
                        .padding()
                        .background(Color.white)
                        .cornerRadius(10)
                }
            }
            
            // OVERLAY DE ÉXITO - AHORA SÍ VISIBLE
            if showSuccess {
                SuccessOverlay {
                    presentationMode.wrappedValue.dismiss()
                }
            }
        }
        .navigationTitle("Confirmar Pedido")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if userManager.addresses.count == 1 { selectedAddress = userManager.addresses.first }
        }
        .paymentSheet(isPresented: $showStripeSheet,
                      paymentSheet: paymentManager.paymentSheet ?? PaymentSheet(paymentIntentClientSecret: "", configuration: PaymentSheet.Configuration()),
                      onCompletion: { result in
            
            paymentManager.onPaymentCompletion(result: result, onSuccess: {
                createFirebaseOrder()
            }, onFailure: { error in
                errorMessage = error
                showError = true
            })
        })
        .alert("Aviso", isPresented: $showError) {
            Button("Ok", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
    }
    
    var canPay: Bool { return selectedAddress != nil && subtotal > 0 }
    
    func startStripePayment() {
        guard canPay else { return }
        let impact = UIImpactFeedbackGenerator(style: .medium); impact.impactOccurred()
        
        paymentManager.preparePayment(amount: subtotal) { success in
            if success {
                showStripeSheet = true
            } else {
                errorMessage = "Error de conexión con el servidor."
                showError = true
            }
        }
    }
    
    func createFirebaseOrder() {
        guard let address = selectedAddress else { return }
        let stripeCardDisplay = PaymentCard(id: "stripe", cardHolder: "Stripe", last4: "4242", brand: "Visa", expiryDate: "12/30")
        
        orderManager.placeOrder(items: cartManager.cartItems, total: subtotal, address: address, card: stripeCardDisplay) { success in
            if success {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.75) {
                    withAnimation {
                        showSuccess = true
                    }
                }
            } else {
                errorMessage = "Pago cobrado, pero error al guardar pedido."
                showError = true
            }
        }
    }
}

// MARK: - Pantalla de Éxito (Overlay Verde)
struct SuccessOverlay: View {
    var onDismiss: () -> Void
    
    var body: some View {
        ZStack {
            Color.superGreen.ignoresSafeArea()
            
            VStack(spacing: 30) {
                Spacer()
                
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 100))
                    .foregroundColor(.white)
                    .shadow(radius: 10)
                    .scaleEffect(1.2)
                
                VStack(spacing: 15) {
                    Text("¡Pedido Exitoso!")
                        .font(.largeTitle.bold())
                        .foregroundColor(.white)
                    
                    Text("Tu pago ha sido confirmado. Estamos preparando tu pedido.")
                        .font(.body)
                        .foregroundColor(.white.opacity(0.9))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
                
                Spacer()
                
                Button(action: onDismiss) {
                    HStack {
                        Text("Finalizar y Volver")
                            .font(.headline.bold())
                        Image(systemName: "arrow.right")
                    }
                    .foregroundColor(.superGreen)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.white)
                    .cornerRadius(25)
                    .padding(.horizontal, 40)
                    .shadow(radius: 5)
                }
                .padding(.bottom, 50)
            }
        }
    }
}

// MARK: - Subvistas Auxiliares
struct SummaryRow: View {
    let title: String; let value: String; var isHighlight: Bool = false
    var body: some View {
        HStack { Text(title).foregroundColor(.gray); Spacer(); Text(value).bold().foregroundColor(isHighlight ? .superGreen : .black) }
    }
}

struct EmptySelectionBox: View {
    let icon: String; let text: String
    var body: some View {
        HStack { Image(systemName: icon).foregroundColor(.blue); Text(text).foregroundColor(.blue); Spacer(); Image(systemName: "chevron.right").foregroundColor(.gray.opacity(0.5)) }
        .padding().background(Color.white).cornerRadius(12).shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}

struct AddressSelectionCard: View {
    let address: Address; let isSelected: Bool
    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack { Image(systemName: isSelected ? "checkmark.circle.fill" : "circle").foregroundColor(isSelected ? .superGreen : .gray.opacity(0.3)); Text(address.street).font(.headline).lineLimit(1) }
            Text(address.colony).font(.caption).foregroundColor(.gray); Text(address.city).font(.caption).foregroundColor(.gray)
        }
        .padding().frame(width: 200, height: 100, alignment: .topLeading).background(Color.white).cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(isSelected ? .green : .clear, lineWidth: 2)).shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}
