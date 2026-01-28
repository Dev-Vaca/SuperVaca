//
//  OrderManager.swift
//  SuperVaca
//
//  Lógica para crear y subir pedidos a Firebase.
//

import Foundation
import Firebase
import FirebaseFirestore
import FirebaseAuth
import Combine

class OrderManager: ObservableObject {
    
    static let shared = OrderManager()
    private let db = Firestore.firestore()
    
    @Published var isLoading = false
    @Published var userOrders: [Order] = []
    
    private init() {}
    
    // Función Maestra: PROCESAR EL PEDIDO
    func placeOrder(items: [CartItem], total: Double, address: Address, card: PaymentCard, completion: @escaping (Bool) -> Void) {
        
        // 1. Verificar usuario logueado
        guard let user = Auth.auth().currentUser else {
            print("Error: No hay usuario logueado")
            completion(false)
            return
        }
        
        isLoading = true
        
        // 2. Crear los "Snapshots" de los productos
        // Convertimos los items del carrito (que solo tienen ID) a items completos con precio y nombre
        var orderItems: [CartItemSnapshot] = []
        
        for item in items {
            // Buscamos los detalles en el ProductManager (memoria local)
            if let product = ProductManager.shared.getProduct(byId: item.id) {
                let snapshot = CartItemSnapshot(
                    id: item.id,
                    name: product.name,
                    quantity: item.quantity,
                    unit: product.unit,
                    priceAtPurchase: product.price, // PRECIO CONGELADO ❄️
                    imageURL: product.imageURLString
                )
                orderItems.append(snapshot)
            }
        }
        
        // 3. Obtener el nombre del usuario (del perfil local)
        let currentUserName = UserManager.shared.currentUserProfile?.name ?? "Cliente SuperVaca"
        
        // 4. Crear el objeto Order
        let newOrder = Order(
            userId: user.uid,
            userName: currentUserName,
            items: orderItems,
            totalAmount: total,
            shippingAddress: address,
            paymentCard: card,
            status: "pending", // Estado inicial: Pendiente
            date: Date()
        )
        
        // 5. Subir a Firebase
        do {
            try db.collection("orders").addDocument(from: newOrder) { error in
                DispatchQueue.main.async {
                    self.isLoading = false
                    
                    if let error = error {
                        print("Error al subir pedido: \(error.localizedDescription)")
                        completion(false)
                    } else {
                        print("✅ Pedido creado con éxito!")
                        // IMPORTANTE: Vaciar el carrito local y remoto
                        CartManager.shared.clearCart()
                        completion(true)
                    }
                }
            }
        } catch {
            print("Error codificando datos: \(error)")
            self.isLoading = false
            completion(false)
        }
    }
    
    //Funcion para recuperar los pedidos del usuario
    func listenToUserOrders() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        // La consulta mágica: "Donde userId == uid"
        db.collection("orders")
            .whereField("userId", isEqualTo: uid)
            .order(by: "date", descending: true) // Los más recientes primero
            .addSnapshotListener { snapshot, error in
                guard let documents = snapshot?.documents else {
                    print("Error bajando historial: \(error?.localizedDescription ?? "")")
                    return
                }
                
                self.userOrders = documents.compactMap { doc -> Order? in
                    try? doc.data(as: Order.self)
                }
            }
    }
    
    func clearData() {
        self.userOrders = []
        print("🧹 OrderManager limpio")
    }
}
