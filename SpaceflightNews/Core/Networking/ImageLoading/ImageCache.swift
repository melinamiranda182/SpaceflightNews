//
//  ImageCache.swift
//  SpaceflightNews
//
//  Created by Melina Miranda on 20/05/2026.
//

import UIKit

/// Manager de caché de imágenes en memoria
/// Utiliza NSCache para gestión automática de memoria bajo presión
final class ImageCache {
    
    // MARK: - Singleton
    static let shared = ImageCache()
    
    // MARK: - Properties
    private let cache: NSCache<NSString, UIImage>
    private let memoryLimit: Int
    private let countLimit: Int
    
    // MARK: - Initialization
    private init() {
        self.cache = NSCache<NSString, UIImage>()
        
        // Configuración de límites
        self.memoryLimit = 100 * 1024 * 1024  // 100 MB
        self.countLimit = 200                  // 200 imágenes max
        
        cache.totalCostLimit = memoryLimit
        cache.countLimit = countLimit
        
        // Limpiar caché en memory warning
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(clearCache),
            name: UIApplication.didReceiveMemoryWarningNotification,
            object: nil
        )
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Public Methods
    
    /// Obtiene imagen del caché
    func get(forKey key: String) -> UIImage? {
        return cache.object(forKey: key as NSString)
    }
    
    /// Guarda imagen en el caché
    func set(_ image: UIImage, forKey key: String) {
        // Calcular costo aproximado (ancho * alto * 4 bytes por pixel)
        let cost = Int(image.size.width * image.size.height * 4)
        cache.setObject(image, forKey: key as NSString, cost: cost)
    }
    
    /// Limpia todo el caché
    @objc func clearCache() {
        cache.removeAllObjects()
        #if DEBUG
        print("🧹 ImageCache: Cache cleared")
        #endif
    }
    
    /// Remueve imagen específica
    func remove(forKey key: String) {
        cache.removeObject(forKey: key as NSString)
    }
    
    // MARK: - Debug Info
    #if DEBUG
    var debugInfo: String {
        """
        📊 ImageCache Info:
        - Memory Limit: \(memoryLimit / 1024 / 1024) MB
        - Count Limit: \(countLimit) images
        """
    }
    #endif
}

