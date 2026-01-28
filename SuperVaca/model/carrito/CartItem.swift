//
//  CartItem.swift
//  SuperVaca
//
//  Modelo de un producto dentro del carrito.
//

import Foundation

struct CartItem: Identifiable, Codable {
    var id: String      // ID del producto (ej: "101")
    var quantity: Double // CANTIDAD DECIMAL (El cambio clave)
}
