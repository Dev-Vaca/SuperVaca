//
//  UserOrdersView.swift
//  SuperVaca
//
//  Historial de pedidos del cliente.
//

import SwiftUI

struct UserOrdersView: View {
    @StateObject var orderManager = OrderManager.shared
    
    var body: some View {
        ZStack {
            Color(.systemGroupedBackground).ignoresSafeArea()
            
            if orderManager.userOrders.isEmpty {
                // ESTADO VACÍO
                VStack(spacing: 20) {
                    Spacer()
                    Image(systemName: "list.bullet.clipboard")
                        .font(.system(size: 80))
                        .foregroundColor(.gray.opacity(0.3))
                    Text("No has realizado pedidos")
                        .font(.title2.bold())
                        .foregroundColor(.gray)
                    Text("Tus compras anteriores aparecerán aquí.")
                        .font(.subheadline)
                        .foregroundColor(.gray.opacity(0.8))
                    Spacer()
                }
            } else {
                // LISTA DE TARJETAS
                ScrollView {
                    LazyVStack(spacing: 20) {
                        ForEach(orderManager.userOrders) { order in
                            OrderCardView(order: order)
                        }
                    }
                    .padding()
                }
            }
        }
        .navigationTitle("Mis Pedidos")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            orderManager.listenToUserOrders()
        }
    }
}

// MARK: - Tarjeta de Pedido (Nuevo Diseño)
struct OrderCardView: View {
    let order: Order
    
    // Función para formatear cantidades (El arreglo del "0")
    func formatQuantity(_ qty: Double) -> String {
        // Si el número es entero (ej: 1.0, 5.0) -> Muestra "1", "5"
        if qty.truncatingRemainder(dividingBy: 1) == 0 {
            return String(format: "%.0f", qty)
        } else {
            // Si tiene decimales (ej: 0.25) -> Muestra "0.250"
            return String(format: "%.3f", qty)
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            
            // 1. CABECERA (Fecha y Estado)
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(order.formattedDate)
                        .font(.caption.bold())
                        .foregroundColor(.gray)
                    Text("Pedido #\(order.id?.prefix(5).uppercased() ?? "---")")
                        .font(.system(.headline, design: .monospaced))
                }
                
                Spacer()
                
                StatusBadge(status: order.status)
            }
            .padding()
            .background(Color(.systemGray6).opacity(0.5))
            
            Divider()
            
            // 2. LISTA DE PRODUCTOS (Detallada)
            VStack(alignment: .leading, spacing: 12) {
                ForEach(order.items) { item in
                    HStack(alignment: .top) {
                        // Cantidad con fondo suave
                        Text(formatQuantity(item.quantity))
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.black)
                            .frame(minWidth: 40)
                            .padding(.vertical, 4)
                            .background(Color(.systemGray6))
                            .cornerRadius(6)
                            .multilineTextAlignment(.center)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.name)
                                .font(.subheadline.bold())
                                .foregroundColor(.black)
                                .lineLimit(2)
                            
                            // Si tu modelo CartItem tiene precio unitario, podrías ponerlo aquí
                            // Text("$\(item.price)").font(.caption).foregroundColor(.gray)
                        }
                        
                        Spacer()
                    }
                }
            }
            .padding()
            
            Divider()
            
            // 3. FOOTER (Total)
            HStack {
                Text("Total Pagado")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                
                Spacer()
                
                Text("$\(String(format: "%.2f", order.totalAmount))")
                    .font(.title3.bold())
                    .foregroundColor(.superGreen) // Asegúrate de tener tu extensión de color
            }
            .padding()
            .background(Color.white)
        }
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
    }
}

// MARK: - Badge de Estado
struct StatusBadge: View {
    let status: String
    
    var config: (color: Color, text: String, icon: String) {
        switch status {
        case "pending":
            return (.orange, "Pendiente", "clock.fill")
        case "shipping":
            return (.blue, "En Camino", "truck.box.fill")
        case "delivered":
            return (.green, "Entregado", "checkmark.seal.fill")
        default:
            return (.gray, "Desconocido", "questionmark")
        }
    }
    
    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: config.icon)
                .font(.caption)
            Text(config.text)
                .font(.caption.bold())
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .foregroundColor(config.color)
        .background(config.color.opacity(0.1))
        .clipShape(Capsule())
        .overlay(
            Capsule().stroke(config.color.opacity(0.3), lineWidth: 1)
        )
    }
}
