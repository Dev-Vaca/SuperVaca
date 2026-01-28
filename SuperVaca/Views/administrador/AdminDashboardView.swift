//
//  AdminDashboardView.swift
//  SuperVaca
//
//  Panel de Control Avanzado para el Dueño.
//  Incluye buscadores, filtros por fecha y estado.
//

import SwiftUI

struct AdminDashboardView: View {
    @StateObject var adminManager = AdminManager.shared
    
    // Variables de Filtro
    @State private var searchText = ""
    @State private var selectedStatusFilter: String = "Todos" // Todos, Pendiente, En Camino...
    @State private var showDateFilter = false
    @State private var startDate = Date().addingTimeInterval(-86400 * 7) // Últimos 7 días por defecto
    @State private var endDate = Date()
    
    // Opciones de estado para el filtro
    let statusOptions = ["Todos", "Pendiente", "En Camino", "Entregado"]
    
    // LÓGICA MAESTRA DE FILTRADO 🧠
    var filteredOrders: [Order] {
        var orders = adminManager.allOrders
        
        // 1. Filtro por Estado
        if selectedStatusFilter != "Todos" {
            let backendStatus = mapStatusToBackend(selectedStatusFilter)
            orders = orders.filter { $0.status == backendStatus }
        }
        
        // 2. Filtro por Fecha (Solo si está activo el toggle visual)
        if showDateFilter {
            orders = orders.filter { order in
                order.date >= startDate && order.date <= endDate.addingTimeInterval(86400) // +1 día para incluir el final
            }
        }
        
        // 3. Filtro por Búsqueda (Nombre de usuario o ID de pedido)
        if !searchText.isEmpty {
            orders = orders.filter { order in
                let nameMatch = order.userName.localizedCaseInsensitiveContains(searchText)
                let idMatch = (order.id ?? "").localizedCaseInsensitiveContains(searchText)
                return nameMatch || idMatch
            }
        }
        
        return orders
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(.systemGroupedBackground).ignoresSafeArea()
                
                VStack(spacing: 0) {
                    
                    // SECCIÓN SUPERIOR: FILTROS
                    VStack(spacing: 12) {
                        // Buscador
                        HStack {
                            Image(systemName: "magnifyingglass").foregroundColor(.gray)
                            TextField("Buscar Cliente o ID...", text: $searchText)
                        }
                        .padding(10)
                        .background(Color.white)
                        .cornerRadius(10)
                        
                        // Filtro de Estado (Scroll Horizontal)
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack {
                                ForEach(statusOptions, id: \.self) { status in
                                    FilterChip(
                                        title: status,
                                        isSelected: selectedStatusFilter == status,
                                        onTap: { selectedStatusFilter = status }
                                    )
                                }
                            }
                        }
                        
                        // Toggle de Fechas
                        Toggle(isOn: $showDateFilter.animation()) {
                            Text("Filtrar por Fechas")
                                .font(.subheadline).bold()
                                .foregroundColor(.gray)
                        }
                        .padding(.top, 5)
                        
                        // Selectores de Fecha (Solo si está activo)
                        if showDateFilter {
                            HStack {
                                DatePicker("De:", selection: $startDate, displayedComponents: .date)
                                    .labelsHidden()
                                Text("-")
                                DatePicker("A:", selection: $endDate, displayedComponents: .date)
                                    .labelsHidden()
                            }
                            .transition(.move(edge: .top).combined(with: .opacity))
                        }
                    }
                    .padding()
                    .background(Color.white)
                    .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 5)
                    .zIndex(1) // Para que la sombra caiga sobre la lista
                    
                    // LISTA DE PEDIDOS
                    if adminManager.isLoading {
                        Spacer()
                        ProgressView("Cargando pedidos...")
                        Spacer()
                    } else if filteredOrders.isEmpty {
                        Spacer()
                        VStack(spacing: 10) {
                            Image(systemName: "tray.fill")
                                .font(.largeTitle)
                                .foregroundColor(.gray)
                            Text("No se encontraron pedidos con estos filtros.")
                                .foregroundColor(.gray)
                        }
                        Spacer()
                    } else {
                        List {
                            ForEach(filteredOrders) { order in
                                ZStack {
                                    // Enlace invisible para navegación
                                    NavigationLink(destination: AdminOrderDetailView(order: order)) {
                                        EmptyView()
                                    }
                                    .opacity(0)
                                    
                                    // Diseño de la tarjeta
                                    AdminOrderRow(order: order)
                                }
                                .listRowBackground(Color.clear)
                                .listRowSeparator(.hidden)
                                .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                            }
                        }
                        .listStyle(.plain)
                        .refreshable {
                            adminManager.listenToAllOrders()
                        }
                    }
                }
            }
            .navigationTitle("Panel de Control")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                adminManager.listenToAllOrders()
            }
        }
    }
    
    // Helper para traducir UI -> Backend
    func mapStatusToBackend(_ uiStatus: String) -> String {
        switch uiStatus {
        case "Pendiente": return "pending"
        case "En Camino": return "shipping"
        case "Entregado": return "delivered"
        default: return ""
        }
    }
}

// MARK: - Componentes Visuales

// 1. Chip de Filtro
struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Text(title)
            .font(.caption.bold())
            .padding(.vertical, 8)
            .padding(.horizontal, 16)
            .background(isSelected ? Color.blue : Color.gray.opacity(0.1))
            .foregroundColor(isSelected ? .white : .black)
            .cornerRadius(20)
            .onTapGesture { onTap() }
    }
}

// 2. Fila de Pedido (Tarjeta)
struct AdminOrderRow: View {
    let order: Order
    
    var statusColor: Color {
        switch order.status {
        case "pending": return .orange
        case "shipping": return .blue
        case "delivered": return .green
        default: return .gray
        }
    }
    
    var statusText: String {
        switch order.status {
        case "pending": return "PENDIENTE"
        case "shipping": return "EN CAMINO"
        case "delivered": return "ENTREGADO"
        default: return "DESC"
        }
    }
    
    var body: some View {
        HStack(spacing: 0) {
            // Barra lateral de estado
            Rectangle()
                .fill(statusColor)
                .frame(width: 6)
            
            VStack(alignment: .leading, spacing: 8) {
                // Fila Superior: ID y Fecha
                HStack {
                    Text("#\(order.id?.prefix(5).uppercased() ?? "---")")
                        .font(.caption.bold())
                        .padding(4)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(4)
                    
                    Spacer()
                    
                    Text(order.formattedDate)
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                // Cliente y Monto
                HStack {
                    VStack(alignment: .leading) {
                        Text(order.userName)
                            .font(.headline)
                        Text("\(order.items.count) productos")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    Spacer()
                    Text("$\(String(format: "%.2f", order.totalAmount))")
                        .font(.title3.bold())
                        .foregroundColor(.black)
                }
                
                Divider()
                
                // Estado
                HStack {
                    Image(systemName: "circle.fill")
                        .font(.system(size: 8))
                        .foregroundColor(statusColor)
                    Text(statusText)
                        .font(.caption.bold())
                        .foregroundColor(statusColor)
                    
                    Spacer()
                    
                    // Flechita
                    Image(systemName: "chevron.right")
                        .foregroundColor(.gray.opacity(0.5))
                }
            }
            .padding(12)
            .background(Color.white)
        }
        .cornerRadius(10)
        .shadow(color: .black.opacity(0.05), radius: 3, x: 0, y: 1)
    }
}
