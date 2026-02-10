//
//  ExploreView.swift
//  SuperVaca
//
//  Vista de Búsqueda y Exploración de productos.
//

import SwiftUI

struct ExploreView: View {
    
    // MARK: - Properties
    @State private var searchText = ""
    
    // CONEXIÓN AL ALMACÉN CENTRAL (Ya tiene los productos listos)
    @ObservedObject var productManager = ProductManager.shared
    
    @State private var filteredProducts: [Product] = [] // Los que mostramos
    @State private var selectedCategory: ProductCategory? = nil
    
    // Configuración de la Cuadrícula
    let columns = [
        GridItem(.flexible(), spacing: 15),
        GridItem(.flexible(), spacing: 15)
    ]
    
    // MARK: - Body
    var body: some View {
        NavigationView {
            ZStack(alignment: .top) {
                Color.white.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    
                    // 1. Barra de Búsqueda
                    searchHeader
                        .padding(.bottom, 10)
                        .background(Color.white)
                    
                    // 2. Filtros de Categoría
                    categoryFilterSection
                        .padding(.bottom, 10)
                        .background(Color.white)
                    
                    // 3. Resultados
                    if productManager.isLoading && productManager.products.isEmpty {
                        Spacer()
                        ProgressView("Sincronizando catálogo...")
                        Spacer()
                    } else {
                        ScrollView {
                            if filteredProducts.isEmpty {
                                emptyStateView
                            } else {
                                // GRID DE PRODUCTOS
                                LazyVGrid(columns: columns, spacing: 15) {
                                    ForEach(filteredProducts) { product in
                                        
                                        // NAVEGACIÓN AL DETALLE
                                        NavigationLink(destination: ProductDetailView(product: product)) {
                                            GridProductCardView(product: product)
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                        .transition(.scale.combined(with: .opacity))
                                        // TRUCO: ID único para refrescar imagen si es necesario
                                        .id(product.id)
                                    }
                                }
                                .padding(.horizontal)
                                .padding(.bottom, 20)
                                .animation(.spring(response: 0.4, dampingFraction: 0.7), value: filteredProducts.count)
                            }
                        }
                        // Ocultar teclado al arrastrar
                        .simultaneousGesture(DragGesture().onChanged({ _ in
                            dismissKeyboard()
                        }))
                    }
                }
            }
            .navigationBarHidden(true)
        }
        // AL APARECER: Inicializamos la lista con lo que ya tiene el Manager
        .onAppear {
            applyFilters()
        }
        // SI CAMBIA EL CATÁLOGO: Refrescamos (por si se descargaron cosas nuevas en background)
        .onChange(of: productManager.products) { _ in
            applyFilters()
        }
    }
    
    // MARK: - Lógica de Filtrado (Local, ¡Rapidísima!)
    func applyFilters() {
        withAnimation(.easeInOut(duration: 0.3)) {
            var result = productManager.products // Usamos la fuente global
            
            // 1. Filtro por Categoría
            if let category = selectedCategory {
                result = result.filter { $0.categoryEnum == category }
            }
            
            // 2. Filtro por Texto
            if !searchText.isEmpty {
                result = result.filter { product in
                    product.name.localizedCaseInsensitiveContains(searchText) ||
                    product.categoryString.localizedCaseInsensitiveContains(searchText)
                }
            }
            
            self.filteredProducts = result
        }
    }
    
    func dismissKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
    
    // MARK: - Subvistas
    
    var searchHeader: some View {
        HStack {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                
                TextField("Buscar frutas, carnes, pan...", text: $searchText)
                    .onChange(of: searchText) { _ in applyFilters() }
                
                if !searchText.isEmpty {
                    Button(action: {
                        withAnimation { searchText = "" }
                        applyFilters()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                    }
                }
            }
            .padding(12)
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
        .padding(.horizontal)
        .padding(.top, 10)
    }
    
    var categoryFilterSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                // Chip "Todos"
                filterChip(title: "Todos", isActive: selectedCategory == nil)
                    .onTapGesture {
                        selectedCategory = nil
                        applyFilters()
                    }
                
                // Chips Categorías
                ForEach(ProductCategory.allCases, id: \.self) { category in
                    filterChip(title: category.rawValue, isActive: selectedCategory == category)
                        .onTapGesture {
                            if selectedCategory == category {
                                selectedCategory = nil
                            } else {
                                selectedCategory = category
                            }
                            applyFilters()
                        }
                }
            }
            .padding(.horizontal)
        }
    }
    
    func filterChip(title: String, isActive: Bool) -> some View {
        Text(title)
            .font(.system(size: 14, weight: .semibold))
            .foregroundColor(isActive ? .white : .black)
            .padding(.vertical, 8)
            .padding(.horizontal, 16)
            .background(isActive ? Color.superGreen : Color.white)
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(isActive ? Color.clear : Color.gray.opacity(0.3), lineWidth: 1)
            )
            .shadow(color: isActive ? Color.superGreen.opacity(0.3) : .clear, radius: 5, x: 0, y: 3)
            .scaleEffect(isActive ? 1.05 : 1.0)
            .animation(.spring(), value: isActive)
    }
    
    var emptyStateView: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "magnifyingglass")
                .font(.system(size: 60))
                .foregroundColor(.gray.opacity(0.3))
                .padding(.bottom, 10)
            
            Text("No encontramos productos")
                .font(.headline)
                .foregroundColor(.gray)
            Text("Intenta buscar con otro nombre o categoría")
                .font(.caption)
                .foregroundColor(.gray.opacity(0.8))
            Spacer()
        }
        .padding(.top, 50)
        .transition(.opacity)
    }
}

// MARK: - Componente: Tarjeta de Grid (OPTIMIZADO CON CACHÉ)
struct GridProductCardView: View {
    let product: Product
    
    var body: some View {
        VStack(alignment: .leading) {
            // Imagen CON CACHÉ Y REINTENTOS
            ZStack(alignment: .center) {
                Color.white
                
                CachedAsyncImage(
                    url: product.imageURL,
                    placeholder: Image(systemName: "photo"),
                    maxRetries: 3
                )
                .frame(height: 100)
                .frame(maxWidth: .infinity)
                .padding(.top, 10)
                .padding(.horizontal, 5)
            }
            
            // Datos
            VStack(alignment: .leading, spacing: 4) {
                Text(product.name)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.black)
                    .lineLimit(2)
                    .frame(height: 40, alignment: .topLeading)
                
                Text(product.unit)
                    .font(.caption)
                    .foregroundColor(.gray)
                
                HStack {
                    Text("$\(String(format: "%.2f", product.price))")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(product.isOffer ? .red : .black)
                    
                    if product.isOffer {
                        Spacer()
                        Text("OFERTA")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundColor(.white)
                            .padding(4)
                            .background(Color.red)
                            .cornerRadius(4)
                    }
                }
            }
            .padding(.horizontal, 10)
            .padding(.bottom, 12)
        }
        .background(Color.white)
        .cornerRadius(15)
        .overlay(
            RoundedRectangle(cornerRadius: 15)
                .stroke(Color.gray.opacity(0.1), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 1)
    }
}

struct ExploreView_Previews: PreviewProvider {
    static var previews: some View {
        ExploreView()
    }
}
