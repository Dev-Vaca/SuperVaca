//
//  HomeView.swift
//  SuperVaca
//
//  Pantalla principal (Dashboard) conectada a la API.
//  Incluye navegación al Detalle del Producto.
//

import SwiftUI

struct HomeView: View {
    
    // MARK: - Properties
    @State private var searchText = ""
    @State private var products: [Product] = []
    @State private var isLoading = true
    private let service = ProductService()
    
    // MARK: - Body
    var body: some View {
        // 1. IMPORTANTE: NavigationView permite navegar a otras pantallas
        NavigationView {
            ZStack(alignment: .top) {
                Color.white.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    
                    // Header
                    headerSection
                        .padding(.horizontal)
                        .padding(.bottom, 10)
                        .padding(.top, 10)
                    
                    // Contenido
                    if isLoading {
                        Spacer()
                        VStack {
                            ProgressView().scaleEffect(1.5)
                            Text("Trayendo productos frescos...")
                                .font(.caption).foregroundColor(.gray).padding(.top, 10)
                        }
                        Spacer()
                    } else {
                        ScrollView(.vertical, showsIndicators: false) {
                            VStack(spacing: 25) {
                                
                                bannerSection
                                
                                // SECCIÓN OFERTAS
                                VStack(alignment: .leading, spacing: 15) {
                                    sectionTitle(title: "Ofertas Exclusivas", actionTitle: "Ver todo")
                                    ScrollView(.horizontal, showsIndicators: false) {
                                        HStack(spacing: 15) {
                                            ForEach(products.filter { $0.isOffer }) { product in
                                                
                                                // NAVEGACIÓN AL DETALLE
                                                NavigationLink(destination: ProductDetailView(product: product)) {
                                                    ProductCardView(product: product)
                                                }
                                                .buttonStyle(PlainButtonStyle()) // Evita efecto azul en el botón
                                            }
                                        }
                                        .padding(.horizontal)
                                    }
                                }
                                
                                // SECCIÓN CATEGORÍAS
                                VStack(alignment: .leading, spacing: 15) {
                                    sectionTitle(title: "Categorías", actionTitle: "")
                                    ScrollView(.horizontal, showsIndicators: false) {
                                        HStack(spacing: 15) {
                                            ForEach(ProductCategory.allCases, id: \.self) { category in
                                                CategoryCardView(category: category)
                                            }
                                        }
                                        .padding(.horizontal)
                                    }
                                }
                                
                                // SECCIÓN NUEVOS
                                VStack(alignment: .leading, spacing: 15) {
                                    sectionTitle(title: "Lo más nuevo", actionTitle: "Ver todo")
                                    ScrollView(.horizontal, showsIndicators: false) {
                                        HStack(spacing: 15) {
                                            ForEach(products.filter { $0.isNew }) { product in
                                                
                                                // NAVEGACIÓN AL DETALLE
                                                NavigationLink(destination: ProductDetailView(product: product)) {
                                                    ProductCardView(product: product)
                                                }
                                                .buttonStyle(PlainButtonStyle())
                                            }
                                        }
                                        .padding(.horizontal)
                                    }
                                }
                                
                                Spacer().frame(height: 50)
                            }
                        }
                        .refreshable { await loadData() }
                    }
                }
            }
            .navigationBarHidden(true) // Ocultamos la barra de navegación nativa
        }
        .task { await loadData() }
    }
    
    // MARK: - Logic Helpers
    func loadData() async {
        do {
            let fetchedProducts = try await service.fetchProducts()
            withAnimation {
                self.products = fetchedProducts
                self.isLoading = false
            }
        } catch {
            print("Error: \(error)")
            self.isLoading = false
        }
    }
    
    // MARK: - Subviews
    var headerSection: some View {
        HStack {
            Image("color_logo")
                .resizable().scaledToFit().frame(width: 30, height: 30)
            Text("Colima, México")
                .font(.system(size: 18, weight: .semibold)).foregroundColor(.gray)
            Spacer()
            Circle()
                .fill(Color.gray.opacity(0.1))
                .frame(width: 35, height: 35)
                .overlay(Image(systemName: "person.fill").foregroundColor(.gray))
        }
    }
    
    var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass").foregroundColor(.gray)
            TextField("Buscar en la tienda", text: $searchText)
        }
        .padding(12)
        .background(Color(.systemGray6))
        .cornerRadius(15)
    }
    
    var bannerSection: some View {
        Image("sign_in_top")
            .resizable().scaledToFill().frame(height: 140)
            .cornerRadius(18).padding(.horizontal)
            .overlay(
                HStack {
                    VStack(alignment: .leading, spacing: 5) {
                        Text("Frescura").font(.system(size: 20, weight: .bold)).foregroundColor(.superGreen)
                        Text("hasta tu hogar").font(.system(size: 14, weight: .medium)).foregroundColor(.black)
                    }
                    .padding(.leading, 30)
                    Spacer()
                }
            )
    }
    
    func sectionTitle(title: String, actionTitle: String) -> some View {
        HStack {
            Text(title).font(.system(size: 22, weight: .bold)).foregroundColor(.black)
            Spacer()
            if !actionTitle.isEmpty {
                Button(actionTitle) { }.font(.system(size: 14, weight: .semibold)).foregroundColor(.superGreen)
            }
        }
        .padding(.horizontal)
    }
}

// MARK: - Componente: Tarjeta de Producto (CON ETIQUETAS Y DISEÑO LIMPIO)
struct ProductCardView: View {
    let product: Product
    
    var body: some View {
        VStack(alignment: .center) {
            
            // 1. ZONA DE IMAGEN
            ZStack(alignment: .topLeading) {
                
                // Imagen desde API
                AsyncImage(url: product.imageURL) { phase in
                    switch phase {
                    case .empty:
                        ProgressView().frame(height: 110)
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(height: 110)
                            .frame(maxWidth: .infinity)
                    case .failure:
                        Image(systemName: "photo")
                            .resizable().scaledToFit().frame(height: 50)
                            .foregroundColor(.gray.opacity(0.3)).frame(height: 110)
                    @unknown default: EmptyView()
                    }
                }
                .padding(.top, 15)
                
                // ETIQUETAS FLOTANTES
                if product.isOffer {
                    Text("OFERTA")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.red)
                        .cornerRadius(8)
                        .padding([.top, .leading], 8)
                } else if product.isNew {
                    Text("NUEVO")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.blue)
                        .cornerRadius(8)
                        .padding([.top, .leading], 8)
                }
            }
            
            // 2. TEXTOS
            VStack(alignment: .leading, spacing: 4) {
                Text(product.name)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.black)
                    .lineLimit(1)
                
                Text(product.unit)
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
                
                HStack {
                    // Precio Rojo si es Oferta
                    Text("$\(String(format: "%.2f", product.price))")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(product.isOffer ? .red : .black)
                }
                .padding(.top, 5)
            }
            .padding(.horizontal, 10)
            .padding(.bottom, 10)
        }
        .frame(width: 160)
        .background(Color.white) // Fondo blanco limpio
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(Color.gray.opacity(0.15), lineWidth: 1)
        )
        .cornerRadius(18)
        .shadow(color: Color.black.opacity(0.03), radius: 5, x: 0, y: 2)
    }
}

// MARK: - Componente: Tarjeta de Categoría
struct CategoryCardView: View {
    let category: ProductCategory
    var bgColor: Color {
        switch category {
        case .fruits: return Color.green.opacity(0.1)
        case .vegetables: return Color.orange.opacity(0.1)
        case .meats: return Color.red.opacity(0.1)
        case .dairy: return Color.blue.opacity(0.1)
        case .bakery: return Color.yellow.opacity(0.1)
        }
    }
    var body: some View {
        HStack(spacing: 12) {
            Image(category.assetImageName)
                .resizable().scaledToFit().frame(width: 40, height: 40)
                .shadow(color: .black.opacity(0.1), radius: 3, x: 0, y: 2)
            Text(category.rawValue)
                .font(.system(size: 16, weight: .semibold)).foregroundColor(.black)
        }
        .padding(.horizontal, 16).padding(.vertical, 12)
        .background(bgColor).cornerRadius(18)
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
    }
}
