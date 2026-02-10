//
//  ProductManager.swift
//  SuperVaca
//
//  Almacén central de productos.
//  Se descargan una vez y se usan en toda la app (Home, Explorar, Carrito).
//

import SwiftUI
import Combine

class ProductManager: ObservableObject {
    
    static let shared = ProductManager()
    
    @Published var products: [Product] = []
    @Published var isLoading = false
    
    private let service = ProductService()
    
    private init() {}
    
    func loadProducts() async {
        // Si ya tenemos productos, no los volvemos a descargar (Ahorra datos y batería)
        if !products.isEmpty { return }
        
        DispatchQueue.main.async { self.isLoading = true }
        
        do {
            let fetched = try await service.fetchProducts()
            DispatchQueue.main.async {
                self.products = fetched
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self.preloadImages()
                }
                self.isLoading = false
                print("✅ Catálogo central cargado: \(fetched.count) productos")
            }
        } catch {
            print("Error cargando catálogo: \(error)")
            DispatchQueue.main.async { self.isLoading = false }
        }
    }
    
    // Helper para obtener un producto por su ID rápidamente
    func getProduct(byId id: String) -> Product? {
        return products.first(where: { $0.id == id })
    }
    
    func preloadImages() {
        for product in products {
            guard let url = product.imageURL else { continue }
            
            // Cargar en background
            DispatchQueue.global(qos: .utility).async {
                _ = ImageCache.shared.load(url: url) { _ in }
            }
        }
    }
}
