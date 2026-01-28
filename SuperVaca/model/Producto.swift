//
//  Product.swift
//  SuperVaca
//
//  Modelo actualizado para consumir API REST.
//

import Foundation

// Codable: Permite convertir el JSON de la nube a este objeto Swift automáticamente.
struct Product: Identifiable, Codable, Equatable {
    let id: String
    let name: String
    let description: String
    let price: Double
    let imageURLString: String
    let categoryString: String
    let unit: String
    
    // NUEVOS CAMPOS
    let isOffer: Bool
    let isNew: Bool
    
    enum CodingKeys: String, CodingKey {
        case id, name, description, price, unit
        case imageURLString = "image_url"
        case categoryString = "category"
        case isOffer = "is_offer"
        case isNew = "is_new"
    }
    
    // Helpers
    var imageURL: URL? {
        return URL(string: imageURLString)
    }
    
    var categoryEnum: ProductCategory {
        return ProductCategory(rawValue: categoryString) ?? .fruits
    }
}

// Mantenemos tu Enum para la lógica de la UI
enum ProductCategory: String, CaseIterable {
    case fruits = "Frutas"
    case vegetables = "Verduras"
    case meats = "Carnes"
    case dairy = "Lácteos"
    case bakery = "Panadería"
    
    var assetImageName: String {
        switch self {
        case .fruits: return "cat_frutas"
        case .vegetables: return "cat_verduras"
        case .meats: return "cat_carnes"
        case .dairy: return "cat_lacteos"
        case .bakery: return "cat_panaderia"
        }
    }
}
