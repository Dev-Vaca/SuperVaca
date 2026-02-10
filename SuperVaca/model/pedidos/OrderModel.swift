//
//  OrderModels.swift
//  SuperVaca
//
//  Modelo de datos para representar un pedido en Firebase.
//

import Foundation
import FirebaseFirestore

struct Order: Identifiable, Codable {
    @DocumentID var id: String?
    var userId: String
    var userName: String // Guardamos el nombre del usuario al momento de la compra
    var items: [CartItemSnapshot]
    var totalAmount: Double
    var shippingAddress: Address
    var status: String // "pending", "shipping", "delivered"
    var date: Date
    
    // Helper para formato de fecha en la UI
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "es_MX")
        return formatter.string(from: date)
    }
}

// "Foto" del producto al momento de comprar (Congela el precio y nombre)
struct CartItemSnapshot: Codable, Identifiable {
    var id: String
    var name: String
    var quantity: Double
    var unit: String
    var priceAtPurchase: Double
    var imageURL: String
}
