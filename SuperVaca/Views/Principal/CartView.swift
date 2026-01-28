//
//  CartView.swift
//  SuperVaca
//
//  Vista del Carrito de Compras.
//

import SwiftUI
import Combine // Importante para la validación

struct CartView: View {
    
    // MARK: - Properties
    @ObservedObject var cartManager = CartManager.shared
    @ObservedObject var productManager = ProductManager.shared
    
    // Estado para la edición manual
    @State private var isEditingQuantity = false
    @State private var editingItem: CartItem?
    
    // Usamos String para controlar cada carácter que se escribe
    @State private var quantityInput: String = ""
    @State private var showCheckout = false
    
    // MARK: - Cálculos
    var totalPrice: Double {
        var total: Double = 0
        for item in cartManager.cartItems {
            if let product = productManager.getProduct(byId: item.id) {
                total += product.price * item.quantity
            }
        }
        return total
    }
    
    // MARK: - Body
    var body: some View {
        NavigationView {
            ZStack {
                Color.white.ignoresSafeArea()
                
                if productManager.products.isEmpty {
                    VStack {
                        ProgressView()
                        Text("Sincronizando catálogo...").font(.caption).foregroundColor(.gray)
                    }
                }
                else if cartManager.cartItems.isEmpty {
                    emptyStateView
                } else {
                    VStack(spacing: 0) {
                        
                        // LISTA
                        ScrollView {
                            VStack(spacing: 15) {
                                ForEach(cartManager.cartItems) { cartItem in
                                    if let product = productManager.getProduct(byId: cartItem.id) {
                                        CartRowView(
                                            product: product,
                                            cartItem: cartItem,
                                            onTapQuantity: {
                                                setupEditing(for: cartItem)
                                            }
                                        )
                                        .id(product.id)
                                    }
                                }
                            }
                            .padding()
                        }
                        
                        // RESUMEN
                        checkoutSection
                    }
                }
            }
            .navigationTitle("Mi Carrito")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    if !cartManager.cartItems.isEmpty {
                        Button { cartManager.clearCart() } label: {
                            Image(systemName: "trash").foregroundColor(.red)
                        }
                    }
                }
            }
            // ALERTA DE EDICIÓN CON VALIDACIÓN ESTRICTA
            .alert("Modificar Cantidad", isPresented: $isEditingQuantity) {
                TextField("Cantidad", text: $quantityInput)
                    .keyboardType(.decimalPad)
                    // AQUÍ ESTÁ EL BLOQUEO REAL
                    .onChange(of: quantityInput) { newValue in
                        validateInput(newValue)
                    }
                
                Button("Cancelar", role: .cancel) { }
                Button("Guardar") { saveQuantity() }
            } message: {
                Text("Ingresa la cantidad exacta (Máximo 3 decimales).")
            }
        }
    }
    
    // MARK: - Lógica de Validación Estricta
    func validateInput(_ newValue: String) {
        // 1. Si está vacío, permitimos borrar
        if newValue.isEmpty { return }
        
        // 2. Filtramos caracteres no numéricos (solo permitimos números y un punto)
        let filtered = newValue.filter { "0123456789.".contains($0) }
        
        if filtered != newValue {
            // Si el usuario pegó texto o escribió letras, lo revertimos
            quantityInput = filtered
            return
        }
        
        // 3. Revisamos los decimales
        if let dotIndex = newValue.firstIndex(of: ".") {
            // Obtenemos lo que hay después del punto
            let decimals = newValue[newValue.index(after: dotIndex)...]
            
            // Si hay más de 3 caracteres después del punto...
            if decimals.count > 3 {
                // ...CORTAMOS el exceso inmediatamente. No dejamos que se escriba.
                quantityInput = String(newValue.dropLast())
            }
        }
        
        // 4. Evitar múltiples puntos (ej: 1.2.3)
        if newValue.filter({ $0 == "." }).count > 1 {
            quantityInput = String(newValue.dropLast())
        }
    }
    
    // MARK: - Subvistas y Helpers
    
    var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "cart.badge.minus")
                .font(.system(size: 80))
                .foregroundColor(.gray.opacity(0.3))
            Text("Tu carrito está vacío")
                .font(.title2.bold())
                .foregroundColor(.gray)
            Text("Parece que aún no has agregado productos frescos.")
                .font(.body)
                .foregroundColor(.gray.opacity(0.8))
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
    }
    
    var checkoutSection: some View {
        VStack(spacing: 20) {
            Rectangle()
                .frame(height: 1)
                .foregroundColor(.gray.opacity(0.1))
            
            VStack(spacing: 10) {
                HStack {
                    Text("Subtotal").foregroundColor(.gray)
                    Spacer()
                    Text("$\(String(format: "%.2f", totalPrice))").bold()
                }
                HStack {
                    Text("Envío").foregroundColor(.gray)
                    Spacer()
                    Text("Gratis").bold().foregroundColor(.superGreen)
                }
                Divider()
                HStack {
                    Text("Total").font(.title2.bold())
                    Spacer()
                    Text("$\(String(format: "%.2f", totalPrice))")
                        .font(.title2.bold())
                        .foregroundColor(.black)
                }
            }
            .padding(.horizontal)
            
            Button(action: { showCheckout = true }) {
                Text("Proceder al Pago")
                    .font(.headline.bold())
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.superGreen)
                    .cornerRadius(15)
                    .shadow(color: Color.superGreen.opacity(0.4), radius: 10, y: 5)
            }
            .sheet(isPresented: $showCheckout) {
                CheckoutView()
            }
            .padding(.horizontal)
            .padding(.bottom, 10)
        }
        .background(Color.white)
        .shadow(color: .black.opacity(0.05), radius: 10, y: -5)
    }
    
    func setupEditing(for item: CartItem) {
        editingItem = item
        // Convertimos el Double a String, limpiando ceros innecesarios
        // Ej: 1.0 -> "1", 0.250 -> "0.250"
        if item.quantity.truncatingRemainder(dividingBy: 1) == 0 {
            quantityInput = String(format: "%.0f", item.quantity)
        } else {
            // Usamos hasta 3 decimales, pero removemos ceros al final si quieres
            // O lo dejamos estricto con 3. Aquí uso 3 fijos para empezar.
            let formatted = String(format: "%.3f", item.quantity)
            // Truco opcional: Limpiar ceros a la derecha si prefieres "0.5" en vez de "0.500"
            // Pero como pediste exactitud, lo dejamos o lo limpiamos según gusto.
            // Para editar es mejor ver el número limpio:
            quantityInput = formatted.replacingOccurrences(of: "0*$", with: "", options: .regularExpression).replacingOccurrences(of: "\\.$", with: "", options: .regularExpression)
        }
        isEditingQuantity = true
    }
    
    func saveQuantity() {
        if let item = editingItem, let newQty = Double(quantityInput) {
            if newQty > 0 {
                CartManager.shared.updateQuantity(productId: item.id, newQuantity: newQty)
            }
        }
    }
}

// MARK: - Fila del Carrito (Sin Cambios)
struct CartRowView: View {
    let product: Product
    let cartItem: CartItem
    var onTapQuantity: () -> Void
    
    var cleanedUnit: String {
        let unit = product.unit.trimmingCharacters(in: .whitespacesAndNewlines)
        let onlyLetters = unit.components(separatedBy: CharacterSet.decimalDigits).joined()
        return onlyLetters.isEmpty ? unit : onlyLetters.lowercased()
    }
    
    var isDecimalAllowed: Bool {
        let u = cleanedUnit
        return u.contains("kg") || u.contains("lt") || u.contains("l") || u.contains("gr")
    }
    
    var step: Double { return isDecimalAllowed ? 0.5 : 1.0 }
    
    var quantityString: String {
        if cartItem.quantity.truncatingRemainder(dividingBy: 1) == 0 {
            return String(format: "%.0f", cartItem.quantity)
        } else {
            return String(format: "%.3f", cartItem.quantity)
        }
    }
    
    var body: some View {
        HStack(spacing: 15) {
            AsyncImage(url: product.imageURL) { phase in
                switch phase {
                case .success(let image):
                    image.resizable().aspectRatio(contentMode: .fit)
                case .failure:
                    Image(systemName: "photo").foregroundColor(.gray.opacity(0.3))
                default:
                    ProgressView()
                }
            }
            .frame(width: 80, height: 80)
            .cornerRadius(12)
            .padding(5)
            .background(Color.white)
            .id(product.imageURLString)
            
            VStack(alignment: .leading, spacing: 5) {
                Text(product.name).font(.system(size: 16, weight: .bold)).lineLimit(1)
                Text("$\(String(format: "%.2f", product.price)) / \(cleanedUnit)").font(.caption).foregroundColor(.gray)
                
                HStack {
                    HStack(spacing: 0) {
                        Button(action: {
                            if cartItem.quantity > step {
                                let newQty = cartItem.quantity - step
                                CartManager.shared.updateQuantity(productId: product.id, newQuantity: newQty)
                            } else {
                                CartManager.shared.removeFromCart(productId: product.id)
                            }
                            let impact = UIImpactFeedbackGenerator(style: .light); impact.impactOccurred()
                        }) {
                            Image(systemName: "minus")
                                .font(.system(size: 14, weight: .bold))
                                .frame(width: 35, height: 35)
                                .background(Color.white)
                                .clipShape(Circle())
                                .foregroundColor(.black)
                                .shadow(color: .black.opacity(0.1), radius: 2, y: 1)
                        }
                        
                        Button(action: { if isDecimalAllowed { onTapQuantity() } }) {
                            Text("\(quantityString) \(cleanedUnit)")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.black)
                                .frame(minWidth: 80)
                                .padding(.horizontal, 5)
                                .multilineTextAlignment(.center)
                                .overlay(isDecimalAllowed ? Rectangle().frame(height: 1).foregroundColor(.gray.opacity(0.3)).offset(y: 10) : nil)
                        }
                        .disabled(!isDecimalAllowed)
                        
                        Button(action: {
                            let newQty = cartItem.quantity + step
                            CartManager.shared.updateQuantity(productId: product.id, newQuantity: newQty)
                            let impact = UIImpactFeedbackGenerator(style: .light); impact.impactOccurred()
                        }) {
                            Image(systemName: "plus")
                                .font(.system(size: 14, weight: .bold))
                                .frame(width: 35, height: 35)
                                .background(Color.white)
                                .clipShape(Circle())
                                .foregroundColor(.black)
                                .shadow(color: .black.opacity(0.1), radius: 2, y: 1)
                        }
                    }
                    .padding(4)
                    .background(Color(.systemGray6))
                    .clipShape(Capsule())
                    
                    Spacer()
                    
                    Text("$\(String(format: "%.2f", product.price * cartItem.quantity))")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.black)
                }
            }
        }
        .padding(10)
        .background(Color.white)
        .cornerRadius(15)
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

struct CartView_Previews: PreviewProvider {
    static var previews: some View {
        CartView()
    }
}
