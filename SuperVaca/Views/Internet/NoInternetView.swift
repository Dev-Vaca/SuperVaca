//
//  NoInternetView.swift
//  SuperVaca
//
//  Pantalla de bloqueo cuando no hay conexión.
//

import SwiftUI

struct NoInternetView: View {
    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()
            
            VStack(spacing: 30) {
                // Icono animado (simbólico)
                Image(systemName: "wifi.slash")
                    .font(.system(size: 100))
                    .foregroundColor(.gray.opacity(0.5))
                    .padding()
                    .background(
                        Circle()
                            .fill(Color.gray.opacity(0.1))
                            .frame(width: 200, height: 200)
                    )
                
                VStack(spacing: 15) {
                    Text("¡Ups! Sin conexión")
                        .font(.title.bold())
                        .foregroundColor(.black)
                    
                    Text("SuperVaca necesita internet para cargar los productos frescos y procesar tus pedidos.")
                        .font(.body)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
                
                // Botón visual (aunque la app reconecta sola, esto da paz mental al usuario)
                Button(action: {
                    // Acción dummy, el monitor hace el trabajo real
                    let impact = UIImpactFeedbackGenerator(style: .medium)
                    impact.impactOccurred()
                }) {
                    Text("Reintentar")
                        .font(.headline.bold())
                        .foregroundColor(.white)
                        .padding()
                        .padding(.horizontal, 40)
                        .background(Color.superGreen)
                        .cornerRadius(25)
                        .shadow(radius: 5)
                }
                .padding(.top, 20)
            }
        }
    }
}

struct NoInternetView_Previews: PreviewProvider {
    static var previews: some View {
        NoInternetView()
    }
}
