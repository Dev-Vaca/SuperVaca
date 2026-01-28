//
//  AdminOrderDetailView.swift
//  SuperVaca
//
//  Detalle completo para gestionar un pedido específico.
//

import SwiftUI

struct AdminOrderDetailView: View {
    let order: Order
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                
                // 1. ESTADO ACTUAL (Header Grande)
                VStack(spacing: 10) {
                    Image(systemName: statusIconName)
                        .font(.system(size: 50))
                        .foregroundColor(statusColor)
                    
                    Text(statusText)
                        .font(.title.bold())
                        .foregroundColor(statusColor)
                    
                    Text("ID: \(order.id ?? "---")")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
                .background(Color.white)
                
                // 2. CLIENTE Y DIRECCIÓN
                VStack(alignment: .leading, spacing: 15) {
                    Text("DETALLES DE ENVÍO")
                        .font(.caption).bold().foregroundColor(.gray)
                    
                    HStack {
                        Image(systemName: "person.circle.fill")
                            .font(.title2).foregroundColor(.blue)
                        Text(order.userName)
                            .font(.headline)
                        Spacer()
                        // Botón Llamar
                        Button(action: {
                            callNumber(phoneNumber: order.shippingAddress.phoneNumber)
                        }) {
                            Image(systemName: "phone.circle.fill")
                                .font(.title)
                                .foregroundColor(.green)
                        }
                    }
                    
                    Divider()
                    
                    HStack(alignment: .top) {
                        Image(systemName: "mappin.circle.fill").foregroundColor(.red)
                        VStack(alignment: .leading) {
                            Text(order.shippingAddress.street)
                                .bold()
                            Text("\(order.shippingAddress.colony), \(order.shippingAddress.city)")
                            Text("CP: \(order.shippingAddress.zipCode)")
                                .foregroundColor(.gray)
                        }
                    }
                }
                .padding()
                .background(Color.white)
                .cornerRadius(12)
                .padding(.horizontal)
                
                // 3. PRODUCTOS
                VStack(alignment: .leading, spacing: 15) {
                    Text("PRODUCTOS (\(order.items.count))")
                        .font(.caption).bold().foregroundColor(.gray)
                    
                    ForEach(order.items) { item in
                        HStack {
                            Text("x\(formatQuantity(item.quantity))") // Usamos el formateador limpio
                                .bold()
                                .padding(6)
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(5)
                            
                            Text(item.name)
                            Spacer()
                            Text("$\(String(format: "%.2f", item.priceAtPurchase))")
                        }
                        Divider()
                    }
                    
                    HStack {
                        Text("Total Pagado")
                            .font(.headline)
                        Spacer()
                        Text("$\(String(format: "%.2f", order.totalAmount))")
                            .font(.title2.bold())
                            .foregroundColor(.superGreen)
                    }
                }
                .padding()
                .background(Color.white)
                .cornerRadius(12)
                .padding(.horizontal)
                
                // 4. ACCIONES DE GESTIÓN (Botones Grandes)
                VStack(spacing: 15) {
                    if order.status == "pending" {
                        ActionButton(title: "Marcar EN CAMINO", color: .blue, icon: "truck.box.fill") {
                            updateStatus(to: "shipping")
                        }
                    }
                    
                    if order.status == "shipping" {
                        ActionButton(title: "Marcar ENTREGADO", color: .green, icon: "checkmark.seal.fill") {
                            updateStatus(to: "delivered")
                        }
                    }
                    
                    if order.status == "delivered" {
                        Text("Este pedido ha sido completado.")
                            .font(.caption)
                            .foregroundColor(.gray)
                            .padding()
                    }
                }
                .padding()
            }
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Detalle Pedido")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true) // <--- ESTO OCULTA EL BOTÓN
    }
    
    // Helpers
    func updateStatus(to newStatus: String) {
        if let id = order.id {
            AdminManager.shared.updateOrderStatus(orderId: id, newStatus: newStatus)
            presentationMode.wrappedValue.dismiss()
        }
    }
    
    func callNumber(phoneNumber: String) {
        let cleanNumber = phoneNumber.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
        if let url = URL(string: "tel://\(cleanNumber)"), UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        }
    }
    
    func formatQuantity(_ qty: Double) -> String {
        if qty.truncatingRemainder(dividingBy: 1) == 0 {
            return String(format: "%.0f", qty)
        } else {
            return String(format: "%.3f", qty)
        }
    }
    
    // Computados Visuales
    var statusColor: Color {
        switch order.status {
        case "pending": return .orange
        case "shipping": return .blue
        case "delivered": return .green
        default: return .gray
        }
    }
    var statusText: String {
        switch order.status {
        case "pending": return "PENDIENTE"
        case "shipping": return "EN CAMINO"
        case "delivered": return "ENTREGADO"
        default: return "DESCONOCIDO"
        }
    }
    var statusIconName: String {
        switch order.status {
        case "pending": return "clock.arrow.circlepath"
        case "shipping": return "truck.box.fill"
        case "delivered": return "checkmark.circle.fill"
        default: return "questionmark"
        }
    }
}

// Botón de Acción Grande
struct ActionButton: View {
    let title: String
    let color: Color
    let icon: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                Text(title)
            }
            .font(.headline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(color)
            .cornerRadius(15)
            .shadow(color: color.opacity(0.4), radius: 5, x: 0, y: 3)
        }
    }
}

// --- TRUCO PARA QUE EL SWIPE SIGA FUNCIONANDO ---
// Al ocultar el botón de atrás, SwiftUI desactiva el gesto.
// Esta extensión lo fuerza a estar activo siempre.
extension UINavigationController: @retroactive UIGestureRecognizerDelegate {
    override open func viewDidLoad() {
        super.viewDidLoad()
        interactivePopGestureRecognizer?.delegate = self
    }
    public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        return viewControllers.count > 1
    }
}
