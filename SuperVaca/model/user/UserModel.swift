//
//  UserModels.swift
//  SuperVaca
//
//  Modelos para la información del perfil del usuario.
//

import Foundation

// MARK: - Dirección de Envío
struct Address: Identifiable, Codable, Equatable {
    var id: String = UUID().uuidString
    var street: String      // Calle y Número
    var colony: String      // Colonia
    var city: String        // Ciudad
    var zipCode: String     // Código Postal
    var phoneNumber: String // Teléfono de contacto
    var isDefault: Bool = false
    
    // Helper para mostrar en una línea
    var fullAddress: String {
        "\(street), \(colony), \(city), CP \(zipCode)"
    }
}

// MARK: - Método de Pago (Tarjeta)
struct PaymentCard: Identifiable, Codable, Equatable {
    var id: String = UUID().uuidString
    var cardHolder: String  // Nombre del titular
    var last4: String       // Solo los últimos 4 dígitos (Por seguridad)
    var brand: String       // Visa, Mastercard, etc.
    var expiryDate: String  // MM/YY
    
    // Determinamos el logo según la marca
    var brandIcon: String {
        if brand.lowercased().contains("visa") { return "visa_logo" } // Necesitarás assets o usar texto
        if brand.lowercased().contains("master") { return "mastercard_logo" }
        return "creditcard.fill" // Icono de sistema por defecto
    }
}

// MARK: - Perfil de Usuario (Para mapear desde Firebase)
struct UserProfile: Codable {
    var id: String
    var email: String
    var name: String
    var addresses: [Address] = []
    var cards: [PaymentCard] = []
}
