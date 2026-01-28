//
//  ProductService.swift
//  SuperVaca
//
//  Servicio encargado de descargar datos de internet.
//

import Foundation

class ProductService {
    
    // Pega aquí tu URL de npoint.io
    private let urlString = "https://api.npoint.io/097f9efbfa469302949d"
    
    func fetchProducts() async throws -> [Product] {
        // 1. Validar URL
        guard let url = URL(string: urlString) else {
            throw URLError(.badURL)
        }
        
        // 2. Hacer la petición a internet (Download)
        // 'await' significa que la app espera aquí sin congelar la pantalla
        let (data, response) = try await URLSession.shared.data(from: url)
        
        // 3. Verificar que el servidor respondió OK (código 200)
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        
        // 4. Decodificar (Traducir JSON -> Swift)
        let products = try JSONDecoder().decode([Product].self, from: data)
        return products
    }
}
