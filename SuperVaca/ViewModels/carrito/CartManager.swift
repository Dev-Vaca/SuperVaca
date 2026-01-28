//
//  CartManager.swift
//  SuperVaca
//
//  Gestiona el carrito de compras en Firebase.
//

import Combine
import SwiftUI
import Firebase
import FirebaseAuth
import FirebaseFirestore

class CartManager: ObservableObject {
    
    // Singleton
    static let shared = CartManager()
    
    private let db = Firestore.firestore()
    
    // Lista de productos en el carrito (ID y Cantidad)
    @Published var cartItems: [CartItem] = []
    
    // Para el "Badge" del tab bar: Contamos cuántos productos ÚNICOS hay.
    // (Porque sumar 0.5 kg + 1 pza = 1.5 items se ve raro en una notificación roja).
    var uniqueItemsCount: Int {
        return cartItems.count
    }
    
    private init() {}
    
    // MARK: - 1. Cargar Carrito (Fetch)
    func fetchCart() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        db.collection("users").document(userId).collection("cart").addSnapshotListener { snapshot, error in
            if let error = error {
                print("Error cargando carrito: \(error.localizedDescription)")
                return
            }
            
            guard let documents = snapshot?.documents else { return }
            
            self.cartItems = documents.compactMap { doc -> CartItem? in
                let id = doc.documentID
                // Leemos como Double. Si falla, asumimos 1.0
                let quantity = doc.data()["quantity"] as? Double ?? 1.0
                return CartItem(id: id, quantity: quantity)
            }
            
            print("🛒 Carrito actualizado: \(self.cartItems.count) productos")
        }
    }
    
    // MARK: - 2. Agregar al Carrito (Add/Merge)
    func addToCart(productId: String, quantity: Double) {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        let docRef = db.collection("users").document(userId).collection("cart").document(productId)
        
        docRef.getDocument { document, error in
            if let document = document, document.exists {
                // Si ya existe, sumamos decimales (Ej: Tenía 0.5, agrego 0.5 -> Total 1.0)
                let currentQty = document.data()?["quantity"] as? Double ?? 0.0
                let newTotal = currentQty + quantity
                docRef.updateData(["quantity": newTotal])
            } else {
                // Si es nuevo, lo creamos
                docRef.setData([
                    "quantity": quantity,
                    "added_at": FieldValue.serverTimestamp()
                ])
            }
        }
    }
    
    // MARK: - 3. Actualizar Cantidad Directa (Para la vista del carrito)
    func updateQuantity(productId: String, newQuantity: Double) {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        let docRef = db.collection("users").document(userId).collection("cart").document(productId)
        
        if newQuantity > 0 {
            docRef.updateData(["quantity": newQuantity])
        } else {
            // Si baja a 0, lo borramos
            removeFromCart(productId: productId)
        }
    }
    
    // MARK: - 4. Eliminar Producto
    func removeFromCart(productId: String) {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        db.collection("users").document(userId).collection("cart").document(productId).delete()
    }
    
    // MARK: - 5. Limpiar Carrito (Checkout)
    func clearCart() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        let cartRef = db.collection("users").document(userId).collection("cart")
        
        cartRef.getDocuments { snapshot, error in
            guard let documents = snapshot?.documents else { return }
            let batch = self.db.batch()
            for doc in documents {
                batch.deleteDocument(doc.reference)
            }
            batch.commit()
        }
    }
}
