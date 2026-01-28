//
//  ProductDetailView.swift
//  SuperVaca
//
//  Pantalla de detalle para un producto individual.
//

import SwiftUI
import Combine

struct ProductDetailView: View {
    
    // MARK: - Properties
    let product: Product
    @Environment(\.presentationMode) var presentationMode
    
    // CAMBIO: Usamos String para controlar el input carácter por carácter
    @State private var quantityInput: String = "1"
    
    // FocusState para cerrar el teclado
    @FocusState private var isInputActive: Bool
    
    // Managers
    @ObservedObject var favoritesManager = FavoritesManager.shared
    
    // MARK: - Helpers de Lógica
    
    var cleanedUnit: String {
        let unit = product.unit.trimmingCharacters(in: .whitespacesAndNewlines)
        let onlyLetters = unit.components(separatedBy: CharacterSet.decimalDigits).joined()
        return onlyLetters.isEmpty ? unit : onlyLetters.lowercased()
    }
    
    var isDecimalAllowed: Bool {
        let u = cleanedUnit
        return u.contains("kg") || u.contains("lt") || u.contains("l") || u.contains("gr")
    }
    
    var step: Double {
        return isDecimalAllowed ? 0.5 : 1.0
    }
    
    // Variable computada para obtener el valor numérico actual
    var currentQuantity: Double {
        return Double(quantityInput) ?? 0.0
    }
    
    // MARK: - Body
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                
                // ------------------------------------------------
                // 1. HEADER (Imagen y Navegación)
                // ------------------------------------------------
                ZStack(alignment: .topLeading) {
                    Color(.systemGray6).ignoresSafeArea()
                    
                    VStack {
                        // Navbar
                        HStack {
                            Button(action: { presentationMode.wrappedValue.dismiss() }) {
                                Image(systemName: "arrow.left")
                                    .font(.system(size: 20, weight: .medium))
                                    .foregroundColor(.black)
                                    .padding(10)
                                    .background(Color.white)
                                    .clipShape(Circle())
                                    .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
                            }
                            Spacer()
                            
                            // Botón Favorito
                            Button(action: {
                                let impact = UIImpactFeedbackGenerator(style: .light)
                                impact.impactOccurred()
                                favoritesManager.toggleFavorite(productId: product.id)
                            }) {
                                Image(systemName: favoritesManager.isFavorite(productId: product.id) ? "heart.fill" : "heart")
                                    .font(.system(size: 20, weight: .medium))
                                    .foregroundColor(favoritesManager.isFavorite(productId: product.id) ? .red : .gray)
                                    .padding(10)
                                    .background(Color.white)
                                    .clipShape(Circle())
                                    .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.top, 10)
                        
                        Spacer()
                        
                        // Imagen
                        AsyncImage(url: product.imageURL) { phase in
                            switch phase {
                            case .success(let image):
                                image.resizable().aspectRatio(contentMode: .fit)
                                    .frame(height: geometry.size.height * 0.30)
                                    .padding(.bottom, 20)
                            default:
                                ZStack {
                                    Color.white.opacity(0.5)
                                    Image(systemName: "photo")
                                        .font(.system(size: 40))
                                        .foregroundColor(.gray.opacity(0.3))
                                }
                                .frame(height: geometry.size.height * 0.30)
                            }
                        }
                        Spacer()
                    }
                }
                .frame(height: geometry.size.height * 0.40)
                .clipShape(RoundedCornerShape(radius: 30, corners: [.bottomLeft, .bottomRight]))
                .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 5)
                .zIndex(1)
                
                // ------------------------------------------------
                // 2. DETALLES (Scroll)
                // ------------------------------------------------
                ScrollView {
                    VStack(alignment: .leading, spacing: 25) {
                        
                        // Títulos
                        VStack(alignment: .leading, spacing: 8) {
                            if product.isOffer {
                                tagView(text: "OFERTA", color: .red)
                            } else if product.isNew {
                                tagView(text: "NUEVO", color: .blue)
                            }
                            
                            Text(product.name)
                                .font(.system(size: 26, weight: .heavy, design: .rounded))
                                .foregroundColor(.black)
                            
                            HStack(alignment: .firstTextBaseline) {
                                Text("$\(String(format: "%.2f", product.price))")
                                    .font(.system(size: 32, weight: .bold, design: .rounded))
                                    .foregroundColor(product.isOffer ? .red : .superGreen)
                                
                                Text("/ " + cleanedUnit)
                                    .font(.system(size: 18, weight: .medium, design: .rounded))
                                    .foregroundColor(.gray)
                            }
                        }
                        
                        Divider()
                        
                        // Descripción
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Descripción")
                                .font(.system(size: 18, weight: .bold, design: .rounded))
                            Text(product.description)
                                .font(.system(size: 16, design: .rounded))
                                .foregroundColor(.gray)
                                .lineSpacing(5)
                        }
                        
                        Divider()
                        
                        // ------------------------------------------------
                        // SELECTOR DE CANTIDAD INTELIGENTE
                        // ------------------------------------------------
                        HStack {
                            Text("Cantidad")
                                .font(.system(size: 18, weight: .bold, design: .rounded))
                            
                            Spacer()
                            
                            HStack(spacing: 0) {
                                // Botón Menos
                                quantityButton(icon: "minus") {
                                    updateQuantity(add: false)
                                    let impact = UIImpactFeedbackGenerator(style: .light)
                                    impact.impactOccurred()
                                }
                                
                                // INPUT MANUAL (CONTROLADO POR STRING)
                                HStack(spacing: 2) {
                                    TextField("1", text: $quantityInput)
                                        // Teclado dinámico
                                        .keyboardType(isDecimalAllowed ? .decimalPad : .numberPad)
                                        .focused($isInputActive)
                                        .multilineTextAlignment(.center)
                                        .font(.system(size: 20, weight: .bold, design: .rounded))
                                        .frame(width: 70)
                                        // VALIDACIÓN EN TIEMPO REAL
                                        .onChange(of: quantityInput) { newValue in
                                            validateInput(newValue)
                                        }
                                    
                                    Text(cleanedUnit)
                                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                                        .foregroundColor(.gray)
                                }
                                .padding(.horizontal, 5)
                                .onTapGesture { isInputActive = true }
                                
                                // Botón Más
                                quantityButton(icon: "plus") {
                                    updateQuantity(add: true)
                                    let impact = UIImpactFeedbackGenerator(style: .light)
                                    impact.impactOccurred()
                                }
                            }
                            .padding(6)
                            .background(Color(.systemGray6))
                            .clipShape(Capsule())
                        }
                        
                        Spacer().frame(height: 100)
                    }
                    .padding(25)
                }
                .onTapGesture { isInputActive = false }
                
                // ------------------------------------------------
                // 3. BARRA INFERIOR (Agregar al Carrito)
                // ------------------------------------------------
                VStack {
                    Button(action: {
                        isInputActive = false
                        addToCart()
                    }) {
                        HStack {
                            Image(systemName: "cart.fill.badge.plus")
                                .font(.headline)
                            Text("Agregar")
                                .font(.headline.bold())
                            Spacer()
                            // Total calculado usando currentQuantity
                            Text("$\(String(format: "%.2f", product.price * currentQuantity))")
                                .font(.title3.bold())
                        }
                        .foregroundColor(.white)
                        .padding(.vertical, 18)
                        .padding(.horizontal, 25)
                        .frame(maxWidth: .infinity)
                        .background(currentQuantity > 0 ? Color.superGreen : Color.gray)
                        .cornerRadius(25)
                    }
                    .disabled(currentQuantity <= 0)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 15)
                .background(Color.white)
                .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: -3)
            }
        }
        .navigationBarHidden(true)
        .background(Color.white.ignoresSafeArea())
    }
    
    // MARK: - Lógica de Validación y Actualización
    
    // Función de botones (+ / -)
    func updateQuantity(add: Bool) {
        var current = Double(quantityInput) ?? 0.0
        
        if add {
            current += step
        } else {
            if current > step {
                current -= step
            } else {
                current = 0
            }
        }
        
        // Formatear de vuelta a String
        if current.truncatingRemainder(dividingBy: 1) == 0 {
            quantityInput = String(format: "%.0f", current)
        } else {
            quantityInput = String(format: "%.3f", current)
        }
    }
    
    // VALIDACIÓN ESTRICTA (Igual que en CartView)
    func validateInput(_ newValue: String) {
        if newValue.isEmpty { return }
        
        // 1. Filtrar caracteres no numéricos
        let filtered = newValue.filter { "0123456789.".contains($0) }
        if filtered != newValue {
            quantityInput = filtered
            return
        }
        
        // 2. Revisar decimales
        if let dotIndex = newValue.firstIndex(of: ".") {
            let decimals = newValue[newValue.index(after: dotIndex)...]
            if decimals.count > 3 {
                // Cortar exceso
                quantityInput = String(newValue.dropLast())
            }
        }
        
        // 3. Evitar múltiples puntos
        if newValue.filter({ $0 == "." }).count > 1 {
            quantityInput = String(newValue.dropLast())
        }
    }
    
    // Agregar al carrito
    func addToCart() {
        var finalQty = Double(quantityInput) ?? 0.0
        
        if !isDecimalAllowed {
            finalQty = round(finalQty)
        }
        
        guard finalQty > 0 else { return }
        
        CartManager.shared.addToCart(productId: product.id, quantity: finalQty)
        
        print("🛒 Agregando \(finalQty) \(cleanedUnit)")
        
        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()
        presentationMode.wrappedValue.dismiss()
    }
    
    // MARK: - Subvistas
    func tagView(text: String, color: Color) -> some View {
        Text(text)
            .font(.system(size: 12, weight: .bold))
            .foregroundColor(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(color)
            .clipShape(Capsule())
    }
    
    func quantityButton(icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.black)
                .frame(width: 35, height: 35)
                .background(Color.white)
                .clipShape(Circle())
                .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
        }
    }
}

// Shape compatible
struct RoundedCornerShape: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}

struct ProductDetailView_Previews: PreviewProvider {
    static var previews: some View {
        let dummyProduct = Product(id: "1", name: "Plátano Tabasco", description: "Fresco.", price: 22.0, imageURLString: "", categoryString: "Frutas", unit: "1kg", isOffer: true, isNew: false)
        ProductDetailView(product: dummyProduct)
    }
}
