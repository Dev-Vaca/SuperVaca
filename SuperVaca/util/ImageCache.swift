//
//  ImageCache.swift
//  SuperVaca
//
//  Sistema de caché y carga de imágenes optimizado
//

import SwiftUI
import Combine

// MARK: - Image Cache Manager
class ImageCache {
    static let shared = ImageCache()
    private init() {}
    
    private let cache = NSCache<NSURL, UIImage>()
    private var loadingResponses = [URL: [UUID: (UIImage?) -> Void]]()
    private let lock = NSLock() // ✅ AÑADIDO: Para thread safety
    
    func image(for url: URL) -> UIImage? {
        return cache.object(forKey: url as NSURL)
    }
    
    func cache(_ image: UIImage, for url: URL) {
        cache.setObject(image, forKey: url as NSURL)
    }
    
    func load(url: URL, completion: @escaping (UIImage?) -> Void) -> UUID {
        let id = UUID()
        
        // Si ya está en caché, devolver inmediatamente
        if let cached = image(for: url) {
            completion(cached)
            return id
        }
        
        // ✅ PROTEGEMOS el acceso al diccionario con lock
        lock.lock()
        
        // Si ya se está descargando, agregar callback
        if loadingResponses[url] != nil {
            loadingResponses[url]?[id] = completion
            lock.unlock()
            return id
        }
        
        // Iniciar nueva descarga
        loadingResponses[url] = [id: completion]
        lock.unlock()
        
        // ✅ CAPTURAMOS self correctamente
        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            guard let self = self else { return }
            
            guard let data = data, let image = UIImage(data: data) else {
                DispatchQueue.main.async { [weak self] in
                    self?.complete(url: url, image: nil)
                }
                return
            }
            
            // Guardar en caché
            self.cache(image, for: url)
            
            DispatchQueue.main.async { [weak self] in
                self?.complete(url: url, image: image)
            }
        }.resume()
        
        return id
    }
    
    private func complete(url: URL, image: UIImage?) {
        lock.lock()
        guard let callbacks = loadingResponses[url] else {
            lock.unlock()
            return
        }
        loadingResponses[url] = nil
        lock.unlock()
        
        for (_, callback) in callbacks {
            callback(image)
        }
    }
    
    func cancel(url: URL, id: UUID) {
        lock.lock()
        loadingResponses[url]?[id] = nil
        lock.unlock()
    }
}

// MARK: - Cached Async Image View (CON REINTENTOS)
struct CachedAsyncImage: View {
    let url: URL?
    let placeholder: Image
    let maxRetries: Int
    
    @State private var loadedImage: UIImage?
    @State private var isLoading = false
    @State private var retryCount = 0
    @State private var loadId: UUID?
    
    init(url: URL?,
         placeholder: Image = Image(systemName: "photo"),
         maxRetries: Int = 3) {
        self.url = url
        self.placeholder = placeholder
        self.maxRetries = maxRetries
    }
    
    var body: some View {
        Group {
            if let image = loadedImage {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } else if isLoading {
                ZStack {
                    placeholder
                        .foregroundColor(.gray.opacity(0.2))
                    ProgressView()
                }
            } else {
                placeholder
                    .foregroundColor(.gray.opacity(0.3))
            }
        }
        .onAppear {
            loadImage()
        }
        .onDisappear {
            cancel()
        }
        .onChange(of: url) { _ in
            loadImage()
        }
    }
    
    private func loadImage() {
        guard let url = url else { return }
        
        // Verificar caché primero
        if let cached = ImageCache.shared.image(for: url) {
            self.loadedImage = cached
            return
        }
        
        // Cargar desde red
        isLoading = true
        let id = ImageCache.shared.load(url: url) { image in
            if let image = image {
                self.loadedImage = image
                self.isLoading = false
                self.retryCount = 0
            } else {
                // Reintentar si falla
                if self.retryCount < self.maxRetries {
                    self.retryCount += 1
                    DispatchQueue.main.asyncAfter(deadline: .now() + Double(self.retryCount) * 0.5) {
                        self.loadImage()
                    }
                } else {
                    self.isLoading = false
                }
            }
        }
        self.loadId = id
    }
    
    private func cancel() {
        guard let url = url, let id = loadId else { return }
        ImageCache.shared.cancel(url: url, id: id)
    }
}
