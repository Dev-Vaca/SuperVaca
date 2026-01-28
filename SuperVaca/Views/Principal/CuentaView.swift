//
//  AccountView.swift
//  SuperVaca
//
//  Vista de perfil para gestionar sesión y datos personales.
//  Permite editar nombre y acceso a Admin.
//

import SwiftUI
import FirebaseAuth

struct AccountView: View {
    
    @StateObject private var viewModel = AuthenticationViewModel()
    @ObservedObject var userManager = UserManager.shared
    
    // Estado para editar nombre
    @State private var isEditingName = false
    @State private var tempName = ""
    
    // CORREO DEL ADMINISTRADOR (Pon aquí el tuyo real)
    let adminEmail = "jckuki21@gmail.com" // <--- CAMBIA ESTO
    
    var body: some View {
        NavigationView {
            List {
                // SECCIÓN 1: DATOS DEL USUARIO (Editable)
                Section {
                    HStack(spacing: 15) {
                        // Avatar (Círculo con inicial o ícono)
                        Circle()
                            .fill(Color.superGreen.opacity(0.1))
                            .frame(width: 60, height: 60)
                            .overlay(
                                Text(initials)
                                    .font(.title2.bold())
                                    .foregroundColor(.superGreen)
                            )
                        
                        VStack(alignment: .leading, spacing: 5) {
                            // Nombre (Con botón de editar)
                            HStack {
                                Text(displayName)
                                    .font(.headline)
                                
                                Button(action: {
                                    tempName = displayName
                                    isEditingName = true
                                }) {
                                    Image(systemName: "pencil.circle.fill")
                                        .foregroundColor(.blue)
                                }
                            }
                            
                            Text(viewModel.user?.email ?? "Sin correo")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                    }
                    .padding(.vertical, 10)
                }
                
                // SECCIÓN 2: ACCESO ADMIN (Solo si es el dueño)
                if let email = viewModel.user?.email, email.lowercased() == adminEmail.lowercased() {
                    Section(header: Text("Administración")) {
                        NavigationLink(destination: AdminDashboardView()) {
                            Label {
                                Text("Panel de Dueño")
                                    .fontWeight(.medium)
                            } icon: {
                                Image(systemName: "crown.fill") // Corona para el rey/dueño
                                    .foregroundColor(.purple)
                            }
                        }
                    }
                }
                
                // SECCIÓN 3: CONFIGURACIÓN CLIENTE
                Section(header: Text("Cuenta y Envíos")) {
                    NavigationLink(destination: UserOrdersView()) {
                        Label("Mis Pedidos", systemImage: "bag.fill")
                            .foregroundColor(.primary)
                    }
                    
                    NavigationLink(destination: AddressListView()) {
                        Label("Direcciones de Envío", systemImage: "map.fill")
                            .foregroundColor(.primary)
                    }
                }
                
                // SECCIÓN 4: SESIÓN
                Section {
                    Button(action: {
                        UserManager.shared.clearData()
                        OrderManager.shared.clearData()
                        CartManager.shared.clearCart()
                        
                        viewModel.signOut()
                    }) {
                        HStack {
                            Label("Cerrar Sesión", systemImage: "rectangle.portrait.and.arrow.right")
                                .foregroundColor(.red)
                            Spacer()
                        }
                    }
                }
            }
            .listStyle(InsetGroupedListStyle())
            .navigationTitle("Mi Cuenta")
            // ALERTA PARA CAMBIAR NOMBRE
            .alert("Cambiar Nombre", isPresented: $isEditingName) {
                TextField("Nuevo nombre", text: $tempName)
                Button("Cancelar", role: .cancel) { }
                Button("Guardar") {
                    if !tempName.isEmpty {
                        userManager.updateUserName(newName: tempName)
                    }
                }
            } message: {
                Text("Ingresa el nombre que aparecerá en tus pedidos.")
            }
        }
        .onAppear {
            // Aseguramos que los datos estén frescos
            userManager.fetchUserProfile()
        }
    }
    
    // Helpers para mostrar datos bonitos
    var displayName: String {
        // Usamos el del perfil si existe, si no "Usuario"
        if let name = userManager.currentUserProfile?.name, !name.isEmpty {
            return name
        }
        return "Usuario"
    }
    
    var initials: String {
        let name = displayName
        // Toma la primera letra
        return String(name.prefix(1)).uppercased()
    }
}

struct AccountView_Previews: PreviewProvider {
    static var previews: some View {
        AccountView()
    }
}
