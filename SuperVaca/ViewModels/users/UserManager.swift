//
//  UserManager.swift
//  SuperVaca
//
//  Gestiona los datos del usuario (Perfil, Direcciones, Tarjetas, Nombre) en Firebase.
//

import SwiftUI
import Firebase
import FirebaseFirestore
import Combine
import FirebaseAuth

class UserManager: ObservableObject {
    
    static let shared = UserManager()
    private let db = Firestore.firestore()
    
    // Datos publicados para la UI
    @Published var addresses: [Address] = []
    @Published var cards: [PaymentCard] = []
    @Published var currentUserProfile: UserProfile?
    @Published var isLoading = false
    
    private init() {}
    
    // 1. Cargar Perfil Completo
    func fetchUserProfile() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        // No ponemos isLoading = true aquí para evitar parpadeos si ya hay datos
        
        // Escuchamos el documento del usuario en tiempo real
        db.collection("users").document(uid).addSnapshotListener { snapshot, error in
            
            if let error = error {
                print("Error cargando perfil: \(error.localizedDescription)")
                return
            }
            
            guard let data = snapshot?.data() else { return }
            
            // Decodificamos en el hilo principal para asegurar que la UI se entere
            DispatchQueue.main.async {
                self.isLoading = false
                
                // Mapear el perfil básico (Nombre y Email)
                let name = data["name"] as? String ?? ""
                let email = data["email"] as? String ?? ""
                
                // Si ya existe el perfil local, solo actualizamos los campos, si no, lo creamos
                if self.currentUserProfile == nil {
                    self.currentUserProfile = UserProfile(id: uid, email: email, name: name)
                } else {
                    self.currentUserProfile?.name = name
                    self.currentUserProfile?.email = email
                }
                
                // Decodificar Direcciones
                if let addressesData = data["addresses"] as? [[String: Any]] {
                    self.addresses = addressesData.compactMap { dict in
                        try? Firestore.Decoder().decode(Address.self, from: dict)
                    }
                }
                
                // Decodificar Tarjetas
                if let cardsData = data["cards"] as? [[String: Any]] {
                    self.cards = cardsData.compactMap { dict in
                        try? Firestore.Decoder().decode(PaymentCard.self, from: dict)
                    }
                }
                
                print("👤 Perfil actualizado: \(name)")
            }
        }
    }
    
    // 2. Guardar Nueva Dirección
    func saveAddress(_ address: Address) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        do {
            let data = try Firestore.Encoder().encode(address)
            
            db.collection("users").document(uid).setData([
                "addresses": FieldValue.arrayUnion([data])
            ], merge: true) { error in
                if let error = error { print("Error guardando dirección: \(error)") }
            }
        } catch { print("Error codificando dirección: \(error)") }
    }
    
    // 3. Guardar Nueva Tarjeta
    func saveCard(_ card: PaymentCard) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        do {
            let data = try Firestore.Encoder().encode(card)
            
            db.collection("users").document(uid).setData([
                "cards": FieldValue.arrayUnion([data])
            ], merge: true) { error in
                if let error = error { print("Error guardando tarjeta: \(error)") }
            }
        } catch { print("Error codificando tarjeta: \(error)") }
    }
    
    // 4. Eliminar Dirección
    func deleteAddress(_ address: Address) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        do {
            let data = try Firestore.Encoder().encode(address)
            db.collection("users").document(uid).updateData([
                "addresses": FieldValue.arrayRemove([data])
            ])
        } catch { print(error) }
    }
    
    // 5. Eliminar Tarjeta
    func deleteCard(_ card: PaymentCard) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        do {
            let data = try Firestore.Encoder().encode(card)
            db.collection("users").document(uid).updateData([
                "cards": FieldValue.arrayRemove([data])
            ])
        } catch { print(error) }
    }
    
    // 6. Actualizar Nombre del Perfil (CORREGIDO PARA UI INSTANTÁNEA)
    func updateUserName(newName: String) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let email = Auth.auth().currentUser?.email ?? ""
        
        // 1. Actualizamos inmediatamente la UI (Optimistic Update)
        // Esto hace que el usuario vea el cambio al instante sin esperar a internet
        DispatchQueue.main.async {
            if self.currentUserProfile != nil {
                self.currentUserProfile?.name = newName
            } else {
                self.currentUserProfile = UserProfile(id: uid, email: email, name: newName)
            }
        }
        
        // 2. Guardamos en Firebase en segundo plano
        db.collection("users").document(uid).setData([
            "name": newName,
            "email": email
        ], merge: true) { error in
            if let error = error {
                print("Error actualizando nombre: \(error)")
                // Si fallara, aquí podríamos revertir el cambio, pero es raro
            } else {
                print("✅ Nombre actualizado en Firebase a: \(newName)")
            }
        }
    }
    
    func clearData() {
        self.addresses = []
        self.cards = []
        self.currentUserProfile = nil
        self.isLoading = false
        print("🧹 UserManager limpio")
    }
}
