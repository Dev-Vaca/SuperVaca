//
//  MainTabView.swift
//  SuperVaca
//
//  Contenedor principal de la navegación. Gestiona las pestañas inferiores (Tab Bar).
//

import SwiftUI

struct MainTabView: View {
    
    @State private var selectedTab = 0
    
    var body: some View {
        // Usamos un color de acento global para la tab bar
        TabView(selection: $selectedTab) {
            
            // Pestaña 1: Tienda (Home)
            HomeView()
                .tabItem {
                    // TRUCO: Redimensionamos la imagen a 24x24 (tamaño estándar de tab bar)
                    // antes de mostrara.
                    Image(uiImage: resizeImage(named: "store_tab", size: CGSize(width: 24, height: 24)))
                        .renderingMode(.template)
                    Text("Tienda")
                }
                .tag(0)
            
            // Pestaña 2: Explorar
            ExploreView()
                .tabItem {
                    Image(systemName: "magnifyingglass")
                    Text("Explorar")
                }
                .tag(1)
            
            // Pestaña 3: Carrito
            CartView()
                .tabItem {
                    Image(systemName: "cart.fill")
                    Text("Carrito")
                }
                .tag(2)
            
            // Pestaña 4: Favoritos
            FavoritesView()
                .tabItem {
                    Image(systemName: "heart.fill")
                    Text("Favoritos")
                }
                .tag(3)
            
            // Pestaña 5: Cuenta
            AccountView()
                .tabItem {
                    Image(systemName: "person.fill")
                    Text("Cuenta")
                }
                .tag(4)
        }
        // Color de los iconos activos (Verde SuperVaca)
        .accentColor(.superGreen)
        // Color de los iconos inactivos (Negro suave para que se vea elegante)
        .onAppear {
            UITabBar.appearance().unselectedItemTintColor = UIColor.black.withAlphaComponent(0.8)
        }
    }
    
    // MARK: - Helper para redimensionar imágenes
    // Esta función toma tu imagen original y la encoge al tamaño que le digas (24x24)
    func resizeImage(named: String, size: CGSize) -> UIImage {
        guard let image = UIImage(named: named) else { return UIImage() }
        
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: size))
        }
    }
}

struct MainTabView_Previews: PreviewProvider {
    static var previews: some View {
        MainTabView()
    }
}
