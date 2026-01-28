//
//  FavoritesManager.swift
//  SuperVaca
//
//  Encargado de agregar y quitar favoritos en Firebase Firestore.
//

import SwiftUI
import Firebase
import FirebaseAuth
import FirebaseFirestore
import Combine

class FavoritesManager: ObservableObject {
    // Singleton para usarlo en toda la app fácilmente
    static let shared = FavoritesManager()
    
    private let db = Firestore.firestore()
    
    // Lista de IDs de productos favoritos (Publicamos cambios para que la UI se actualice)
    @Published var favoriteProductIDs: Set<String> = []
    
    private init() {}
    
    // MARK: - 1. Cargar Favoritos al iniciar
    func fetchFavorites() {
        // Verificamos que haya usuario logueado
        guard let userId = Auth.auth().currentUser?.uid else {
            print("⚠️ No hay usuario logueado para cargar favoritos.")
            return
        }
        
        // Escuchamos la colección en tiempo real
        db.collection("users").document(userId).collection("favorites").addSnapshotListener { snapshot, error in
            if let error = error {
                print("❌ Error cargando favoritos: \(error.localizedDescription)")
                return
            }
            
            guard let documents = snapshot?.documents else { return }
            
            // Actualizamos la lista local
            self.favoriteProductIDs = Set(documents.map { $0.documentID })
            print("✅ Favoritos sincronizados: \(self.favoriteProductIDs.count) productos")
        }
    }
    
    // MARK: - 2. Alternar Favorito (Agregar/Quitar)
    func toggleFavorite(productId: String) {
        guard let userId = Auth.auth().currentUser?.uid else {
            print("❌ Error: Usuario no logueado. No se puede guardar favorito.")
            return
        }
        
        let docRef = db.collection("users").document(userId).collection("favorites").document(productId)
        
        if favoriteProductIDs.contains(productId) {
            // Si ya existe, lo borramos (Quitar de favoritos)
            docRef.delete() { error in
                if let error = error {
                    print("Error al borrar favorito: \(error)")
                } else {
                    print("💔 Eliminado de favoritos: \(productId)")
                }
            }
        } else {
            // Si no existe, lo creamos (Agregar a favoritos)
            docRef.setData(["added_at": FieldValue.serverTimestamp()]) { error in
                if let error = error {
                    print("Error al guardar favorito: \(error)")
                } else {
                    print("❤️ Agregado a favoritos: \(productId)")
                }
            }
        }
    }
    
    // MARK: - 3. Verificar si es favorito (Helper visual)
    func isFavorite(productId: String) -> Bool {
        return favoriteProductIDs.contains(productId)
    }
}
