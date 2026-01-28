//
//  AdminManager.swift
//  SuperVaca
//
//  Lógica exclusiva para el dueño de la tienda.
//

import Foundation
import FirebaseFirestore
import Combine

class AdminManager: ObservableObject {
    static let shared = AdminManager()
    private let db = Firestore.firestore()
    
    @Published var allOrders: [Order] = []
    @Published var isLoading = false
    
    private init() {}
    
    // Escuchar TODOS los pedidos de la base de datos en tiempo real
    func listenToAllOrders() {
        isLoading = true
        db.collection("orders")
            .order(by: "date", descending: true) // Los más nuevos arriba
            .addSnapshotListener { snapshot, error in
                self.isLoading = false
                guard let documents = snapshot?.documents else {
                    print("Error bajando pedidos admin: \(error?.localizedDescription ?? "")")
                    return
                }
                
                self.allOrders = documents.compactMap { doc -> Order? in
                    try? doc.data(as: Order.self)
                }
            }
    }
    
    // Función para cambiar estado
    func updateOrderStatus(orderId: String, newStatus: String) {
        db.collection("orders").document(orderId).updateData([
            "status": newStatus
        ]) { error in
            if let error = error { print("Error: \(error)") }
        }
    }
}
