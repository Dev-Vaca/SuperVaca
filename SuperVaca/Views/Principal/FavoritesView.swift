//
//  FavoritesView.swift
//  SuperVaca
//
//  Pantalla que muestra solo los productos guardados.
//

import SwiftUI

struct FavoritesView: View {
    
    @State private var allProducts: [Product] = []
    @State private var isLoading = true
    @ObservedObject var favoritesManager = FavoritesManager.shared
    private let service = ProductService()
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.white.ignoresSafeArea()
                
                if isLoading {
                    ProgressView()
                } else if favoritesManager.favoriteProductIDs.isEmpty {
                    // Estado Vacío
                    VStack(spacing: 15) {
                        Image(systemName: "heart.slash")
                            .font(.system(size: 60))
                            .foregroundColor(.gray.opacity(0.3))
                        Text("Aún no tienes favoritos")
                            .font(.headline)
                            .foregroundColor(.gray)
                        Text("Dale corazón a los productos que te gusten para verlos aquí.")
                            .font(.caption)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                } else {
                    // Lista de Favoritos
                    ScrollView {
                        VStack(spacing: 15) {
                            // Filtramos: De todos los productos, dame solo los que están en favoritos
                            ForEach(allProducts.filter { favoritesManager.isFavorite(productId: $0.id) }) { product in
                                NavigationLink(destination: ProductDetailView(product: product)) {
                                    FavoriteRowView(product: product)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Mis Favoritos")
            .navigationBarTitleDisplayMode(.inline)
        }
        .task {
            await loadData()
        }
    }
    
    func loadData() async {
        do {
            let fetched = try await service.fetchProducts()
            self.allProducts = fetched
            self.isLoading = false
        } catch {
            print("Error: \(error)")
            self.isLoading = false
        }
    }
}

// Fila bonita para la lista de favoritos
struct FavoriteRowView: View {
    let product: Product
    
    var body: some View {
        HStack {
            // ✅ CAMBIO: AsyncImage → CachedAsyncImage
            CachedAsyncImage(
                url: product.imageURL,
                placeholder: Image(systemName: "photo"),
                maxRetries: 3
            )
            .frame(width: 70, height: 70)
            .cornerRadius(10)
            .padding(5)
            
            VStack(alignment: .leading, spacing: 5) {
                Text(product.name)
                    .font(.headline)
                    .lineLimit(1)
                
                Text(product.unit)
                    .font(.caption)
                    .foregroundColor(.gray)
                
                Text("$\(String(format: "%.2f", product.price))")
                    .font(.subheadline.bold())
                    .foregroundColor(.superGreen)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(.gray.opacity(0.5))
        }
        .padding(10)
        .background(Color.white)
        .cornerRadius(15)
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}
