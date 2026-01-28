//
//  AddressFormView.swift
//  SuperVaca
//
//  Formulario para agregar una nueva dirección.
//

import SwiftUI

struct AddressFormView: View {
    @Environment(\.presentationMode) var presentationMode
    
    @State private var street = ""
    @State private var colony = ""
    @State private var city = "Colima" // Default
    @State private var zipCode = ""
    @State private var phone = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Ubicación")) {
                    TextField("Calle y Número", text: $street)
                    TextField("Colonia", text: $colony)
                    TextField("Ciudad", text: $city)
                    TextField("Código Postal", text: $zipCode)
                        .keyboardType(.numberPad)
                }
                
                Section(header: Text("Contacto")) {
                    TextField("Teléfono", text: $phone)
                        .keyboardType(.phonePad)
                }
                
                Button(action: saveAddress) {
                    Text("Guardar Dirección")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(isFormValid ? Color.superGreen : Color.gray)
                        .cornerRadius(10)
                }
                .disabled(!isFormValid)
                .listRowBackground(Color.clear)
            }
            .navigationTitle("Nueva Dirección")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { presentationMode.wrappedValue.dismiss() }
                }
            }
        }
    }
    
    var isFormValid: Bool {
        !street.isEmpty && !colony.isEmpty && !zipCode.isEmpty && !phone.isEmpty
    }
    
    func saveAddress() {
        let newAddress = Address(
            street: street,
            colony: colony,
            city: city,
            zipCode: zipCode,
            phoneNumber: phone,
            isDefault: false
        )
        
        UserManager.shared.saveAddress(newAddress)
        presentationMode.wrappedValue.dismiss()
    }
}
