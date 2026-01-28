//
//  PaymentManager.swift
//  SuperVaca
//
//  Gestiona la pasarela de pagos con Stripe (INTEGRACIÓN REAL).
//

import SwiftUI
import StripePaymentSheet
import Combine

class PaymentManager: ObservableObject {
    
    static let shared = PaymentManager()
    
    // ESTADO DEL PAGO
    @Published var paymentSheet: PaymentSheet?
    @Published var paymentResult: PaymentSheetResult?
    @Published var isProcessing = false
    
    // ---------------------------------------------------------
    // CONFIGURACIÓN OBLIGATORIA
    // ---------------------------------------------------------
    
    // 1. TU LLAVE PÚBLICA DE STRIPE (Sácala del Dashboard de Stripe)
    private let stripePublishableKey = "pk_test_51SuRwDFf8vA6TL4vP7WqNABLOJLyTKvVyM7PxsSHZrFqLlgGMonbft5oPDxHUjxbebEnmtxFmaMqa9uIksExlRtY00LqO47YNN"
    
    // 2. TU URL DE RENDER (Asegúrate de que termine en /create-payment-intent)
    // Nota: Revisa si tu proyecto en Render se llama "superada-pagos" o "supervaca-pagos"
    private let backendUrl = "https://superada-pagos.onrender.com/create-payment-intent"
    
    // ---------------------------------------------------------
    
    private init() {
        // Configuramos Stripe al iniciar
        STPAPIClient.shared.publishableKey = stripePublishableKey
    }
    
    // 1. Preparar el pago (Pedirle al servidor el "Client Secret")
    func preparePayment(amount: Double, completion: @escaping (Bool) -> Void) {
        
        self.isProcessing = true
        self.paymentSheet = nil // Limpiamos cualquier hoja anterior
        
        // Validamos la URL
        guard let url = URL(string: backendUrl) else {
            print("❌ Error: URL del servidor inválida")
            self.isProcessing = false
            completion(false)
            return
        }
        
        // Convertimos el monto a centavos (Stripe usa enteros: $10.00 -> 1000)
        let amountInCents = Int(amount * 100)
        
        // Preparamos la petición POST
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "amount": amountInCents,
            "currency": "mxn"
        ]
        
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        print("🔌 Conectando con Servidor: $\(amount) MXN...")
        
        // Hacemos la llamada a la red
        URLSession.shared.dataTask(with: request) { data, response, error in
            // Volvemos al hilo principal para actualizar la UI
            DispatchQueue.main.async {
                self.isProcessing = false
                
                // 1. Verificamos errores de red
                if let error = error {
                    print("❌ Error de conexión: \(error.localizedDescription)")
                    completion(false)
                    return
                }
                
                guard let data = data else {
                    print("❌ Error: No se recibieron datos del servidor.")
                    completion(false)
                    return
                }
                
                // 2. Intentamos leer el JSON del servidor
                do {
                    if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                       let clientSecret = json["clientSecret"] as? String {
                        
                        print("✅ Secreto de pago recibido. Configurando Stripe...")
                        
                        // 3. Configuramos la Hoja de Pago
                        var configuration = PaymentSheet.Configuration()
                        configuration.merchantDisplayName = "SuperVaca Tienda"
                        configuration.allowsDelayedPaymentMethods = true
                        
                        // Inicializamos la hoja real con el secreto
                        self.paymentSheet = PaymentSheet(paymentIntentClientSecret: clientSecret, configuration: configuration)
                        completion(true)
                        
                    } else {
                        print("❌ Error: El servidor no devolvió un 'clientSecret'.")
                        // Imprimir respuesta para depurar si falla
                        let responseString = String(data: data, encoding: .utf8)
                        print("Respuesta del servidor: \(responseString ?? "N/A")")
                        completion(false)
                    }
                } catch {
                    print("❌ Error procesando JSON: \(error.localizedDescription)")
                    completion(false)
                }
            }
        }.resume()
    }
    
    // 2. Resultado del Pago (Callback de la hoja de Stripe)
    func onPaymentCompletion(result: PaymentSheetResult, onSuccess: @escaping () -> Void, onFailure: @escaping (String) -> Void) {
        self.paymentResult = result
        
        switch result {
        case .completed:
            print("💰 PAGO EXITOSO: Verificado por Stripe")
            onSuccess()
        case .canceled:
            print("⚠️ Pago cancelado por el usuario")
            onFailure("Proceso cancelado")
        case .failed(let error):
            print("❌ Pago fallido: \(error.localizedDescription)")
            onFailure(error.localizedDescription)
        }
    }
}
