//
//  AddressListView.swift
//  SuperVaca
//
//  Lista de direcciones guardadas.
//  Diseño "Delivery Card" Premium con Swipe nativo.
//

import SwiftUI

struct AddressListView: View {
    @ObservedObject var userManager = UserManager.shared
    @State private var showAddForm = false
    
    var body: some View {
        ZStack {
            // Fondo general
            Color(.systemGroupedBackground).ignoresSafeArea()
            
            if userManager.addresses.isEmpty {
                emptyStateView
            } else {
                // Usamos List para tener el SWIPE nativo perfecto
                List {
                    ForEach(userManager.addresses) { address in
                        AddressCardView(address: address)
                            // Trucos para que la lista parezca una pila de tarjetas
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                    }
                    .onDelete { indexSet in
                        indexSet.forEach { index in
                            let address = userManager.addresses[index]
                            userManager.deleteAddress(address)
                        }
                    }
                }
                .listStyle(.plain) // Estilo plano para personalizar todo
            }
            
            // BOTÓN FLOTANTE (FAB)
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button(action: { showAddForm = true }) {
                        Image(systemName: "plus")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 60, height: 60)
                            .background(Color.superGreen)
                            .clipShape(Circle())
                            .shadow(color: Color.superGreen.opacity(0.4), radius: 10, x: 0, y: 5)
                    }
                    .padding()
                }
            }
        }
        .navigationTitle("Mis Direcciones")
        .sheet(isPresented: $showAddForm) {
            AddressFormView()
        }
    }
    
    // Vista Estado Vacío
    var emptyStateView: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(Color.superGreen.opacity(0.1))
                    .frame(width: 120, height: 120)
                Image(systemName: "map.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.superGreen)
            }
            
            Text("¿A dónde enviamos?")
                .font(.title2.bold())
                .foregroundColor(.gray)
            
            Text("Agrega tu casa u oficina para recibir tus pedidos.")
                .font(.subheadline)
                .foregroundColor(.gray.opacity(0.8))
        }
    }
}

// MARK: - Diseño "Delivery Card" Premium
struct AddressCardView: View {
    let address: Address
    
    var body: some View {
        HStack(spacing: 0) {
            // 1. BARRA DE ACENTO LATERAL
            // Le da un toque de color y elegancia
            Rectangle()
                .fill(Color.superGreen)
                .frame(width: 6)
            
            // 2. CONTENIDO PRINCIPAL
            VStack(alignment: .leading, spacing: 12) {
                
                // Encabezado: Icono + Calle
                HStack(alignment: .center, spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(Color.blue.opacity(0.1))
                            .frame(width: 40, height: 40)
                        Image(systemName: "house.fill")
                            .font(.system(size: 18))
                            .foregroundColor(.blue)
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(address.street)
                            .font(.headline)
                            .foregroundColor(.primary)
                            .lineLimit(1)
                        
                        Text(address.colony)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .textCase(.uppercase)
                    }
                    
                    Spacer()
                    
                    // Indicador visual (opcional, como un check o flecha)
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.gray.opacity(0.5))
                }
                
                Divider() // Línea separadora sutil
                
                // Detalles: Ciudad y Teléfono
                HStack(spacing: 20) {
                    // Ciudad / CP
                    HStack(spacing: 6) {
                        Image(systemName: "mappin.and.ellipse")
                            .font(.caption)
                            .foregroundColor(.orange)
                        Text("\(address.city), CP \(address.zipCode)")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    
                    Spacer()
                    
                    // Teléfono
                    HStack(spacing: 6) {
                        Image(systemName: "phone.fill")
                            .font(.caption)
                            .foregroundColor(.green)
                        Text(address.phoneNumber)
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                }
            }
            .padding(16)
            .background(Color.white)
        }
        // DECORACIÓN DE LA TARJETA
        .background(Color.white)
        .cornerRadius(12)
        // Sombra suave para darle profundidad (efecto flotante)
        .shadow(color: Color.black.opacity(0.08), radius: 5, x: 0, y: 2)
        // Borde muy sutil
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.gray.opacity(0.1), lineWidth: 1)
        )
    }
}

struct AddressListView_Previews: PreviewProvider {
    static var previews: some View {
        AddressListView()
    }
}
