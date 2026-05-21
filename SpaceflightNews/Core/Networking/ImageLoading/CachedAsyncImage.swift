//
//  CachedAsyncImage.swift
//  SpaceflightNews
//
//  Created by Melina Miranda on 20/05/2026.
//

import SwiftUI

/// Vista que carga imágenes con caché automático
/// Mejora performance evitando recargar imágenes ya vistas
struct CachedAsyncImage<Content: View, Placeholder: View>: View {
    
    // MARK: - Properties
    private let url: URL?
    private let content: (Image) -> Content
    private let placeholder: () -> Placeholder
    
    @State private var loadedImage: UIImage?
    @State private var isLoading = false
    
    
    // MARK: - Initialization
    init(
        url: URL?,
        @ViewBuilder content: @escaping (Image) -> Content,
        @ViewBuilder placeholder: @escaping () -> Placeholder
    ) {
        self.url = url
        self.content = content
        self.placeholder = placeholder
    }
    
    // MARK: - Body
    var body: some View {
        Group {
            if let image = loadedImage {
                content(Image(uiImage: image))
            } else {
                placeholder()
                    .task {
                        await loadImage()
                    }
            }
        }
    }
    
    // MARK: - Private Methods
    private func loadImage() async {
        guard !isLoading, let url = url else { return }
        
        #if DEBUG
        print("🖼️ Attempting to load image:")
        print("   URL: \(url.absoluteString)")
        print("   Scheme: \(url.scheme ?? "none")")
        print("   Host: \(url.host ?? "none")")
        #endif
        
        let cacheKey = url.absoluteString
        
        // 1. Verificar caché primero
        if let cachedImage = ImageCache.shared.get(forKey: cacheKey) {
            loadedImage = cachedImage
            return
        }
        
        // 2. Descargar imagen
        isLoading = true
        defer { isLoading = false }
        
        do {
            // Configurar URLSession con timeout más corto para imágenes
            let configuration = URLSessionConfiguration.default
            configuration.timeoutIntervalForRequest = 15
            configuration.timeoutIntervalForResource = 30
            let imageSession = URLSession(configuration: configuration)
            
            let (data, response) = try await imageSession.data(from: url)
            
            // Verificar que la respuesta sea válida
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                #if DEBUG
                print("⚠️ Invalid response for image: \(url.absoluteString)")
                #endif
                return
            }
            
            guard let image = UIImage(data: data) else {
                #if DEBUG
                print("⚠️ Could not create image from data: \(url.absoluteString)")
                #endif
                return
            }
            
            // 3. Guardar en caché
            ImageCache.shared.set(image, forKey: cacheKey)
            
            // 4. Actualizar UI solo si la tarea no fue cancelada
            guard !Task.isCancelled else { return }
            
            await MainActor.run {
                self.loadedImage = image
            }
        } catch is CancellationError {
            // Tarea cancelada - esto es normal, no logear
            return
        } catch let urlError as URLError where urlError.code == .cancelled {
            // URLError de cancelación - también normal
            return
        } catch {
            #if DEBUG
            // Logging simplificado para errores reales
            print("❌ Error loading image: \(error.localizedDescription)")
            print("   URL: \(url.absoluteString)")
            #endif
        }
    }
}

// MARK: - Convenience Initializers
extension CachedAsyncImage where Content == Image {
    init(
        url: URL?,
        @ViewBuilder placeholder: @escaping () -> Placeholder
    ) {
        self.init(
            url: url,
            content: { $0.resizable() },
            placeholder: placeholder
        )
    }
}

extension CachedAsyncImage where Placeholder == Color {
    init(
        url: URL?,
        @ViewBuilder content: @escaping (Image) -> Content
    ) {
        self.init(
            url: url,
            content: content,
            placeholder: { Color.gray.opacity(0.2) }
        )
    }
}

// MARK: - Previews
#Preview("Con imagen") {
    CachedAsyncImage(
        url: URL(string: "https://picsum.photos/200")
    ) { image in
        image
            .resizable()
            .aspectRatio(contentMode: .fill)
    } placeholder: {
        ProgressView()
    }
    .frame(width: 200, height: 200)
    .clipShape(RoundedRectangle(cornerRadius: 12))
}

#Preview("Con placeholder") {
    CachedAsyncImage(
        url: URL(string: "https://invalid-url.com/image.jpg")
    ) { image in
        image
            .resizable()
            .aspectRatio(contentMode: .fill)
    } placeholder: {
        Rectangle()
            .fill(Color.gray.opacity(0.2))
            .overlay {
                Image(systemName: "photo")
                    .foregroundStyle(.tertiary)
            }
    }
    .frame(width: 200, height: 200)
    .clipShape(RoundedRectangle(cornerRadius: 12))
}

