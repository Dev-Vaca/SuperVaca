//
//  NetworkMonitor.swift
//  SuperVaca
//
//  Detecta si hay conexión a internet en tiempo real.
//

import Foundation
import Network
import Combine

class NetworkMonitor: ObservableObject {
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitor")
    
    // Publicamos el estado para que la App sepa cuándo cambiar de vista
    @Published var isConnected: Bool = true
    
    init() {
        monitor.pathUpdateHandler = { path in
            // Esto se ejecuta en segundo plano, así que volvemos al hilo principal
            // para actualizar la UI
            DispatchQueue.main.async {
                self.isConnected = path.status == .satisfied
            }
        }
        monitor.start(queue: queue)
    }
}
