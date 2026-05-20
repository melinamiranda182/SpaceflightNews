//
//  NetworkService.swift
//  SpaceflightNews
//
//  Created by Melina Miranda on 19/05/2026.
//

import Foundation

/// Errores específicos de red
enum NetworkError: LocalizedError {
    case invalidURL
    case invalidResponse
    case httpError(statusCode: Int)
    case decodingError
    case noData
    case unknown(Error)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "La URL es inválida"
        case .invalidResponse:
            return "Respuesta del servidor inválida"
        case .httpError(let statusCode):
            return "Error del servidor (código \(statusCode))"
        case .decodingError:
            return "Error al procesar los datos"
        case .noData:
            return "No se recibieron datos"
        case .unknown(let error):
            return "Error desconocido: \(error.localizedDescription)"
        }
    }
}

/// Servicio de red genérico y reutilizable
protocol NetworkServiceProtocol {
    func request<T: Decodable>(_ endpoint: APIEndpoint) async throws -> T
}

final class NetworkService: NetworkServiceProtocol {
    private let session: URLSession
    private let decoder: JSONDecoder
    
    init(session: URLSession = .shared) {
        self.session = session
        self.decoder = JSONDecoder()
        // No usar conversión automática porque usamos CodingKeys manuales
        // self.decoder.keyDecodingStrategy = .convertFromSnakeCase
    }
    
    /// Inicializador con configuración personalizada para evitar warnings de cache
    static func createDefault() -> NetworkService {
        let configuration = URLSessionConfiguration.default
        
        #if DEBUG
        // En DEBUG: Sin cache para siempre tener datos frescos
        configuration.requestCachePolicy = .reloadIgnoringLocalCacheData
        configuration.urlCache = nil
        #else
        // En RELEASE: Cache habilitado para mejor performance
        let memoryCapacity = 50 * 1024 * 1024 // 50 MB
        let diskCapacity = 100 * 1024 * 1024 // 100 MB
        let cache = URLCache(memoryCapacity: memoryCapacity, diskCapacity: diskCapacity)
        configuration.urlCache = cache
        configuration.requestCachePolicy = .returnCacheDataElseLoad
        #endif
        
        // Configuración de timeout
        configuration.timeoutIntervalForRequest = 30
        configuration.timeoutIntervalForResource = 300
        
        let session = URLSession(configuration: configuration)
        return NetworkService(session: session)
    }
    
    func request<T: Decodable>(_ endpoint: APIEndpoint) async throws -> T {
        guard let url = endpoint.url else {
            throw NetworkError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method.rawValue
        request.allHTTPHeaderFields = endpoint.headers
        
        #if DEBUG
        // En desarrollo, siempre recargar
        request.cachePolicy = .reloadIgnoringLocalCacheData
        #else
        request.cachePolicy = .returnCacheDataElseLoad
        #endif
        
        do {
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw NetworkError.invalidResponse
            }
            
            guard (200...299).contains(httpResponse.statusCode) else {
                throw NetworkError.httpError(statusCode: httpResponse.statusCode)
            }
            
            do {
                let decodedData = try decoder.decode(T.self, from: data)
                return decodedData
            } catch {
                #if DEBUG
                // Log detallado del error de decodificación
                print("❌ DECODING ERROR:")
                print("📍 URL: \(url.absoluteString)")
                print("📦 Response Status: \(httpResponse.statusCode)")
                
                if let jsonString = String(data: data, encoding: .utf8) {
                    print("📄 JSON Response:")
                    print(jsonString.prefix(1000)) // Primeros 1000 caracteres
                }
                
                print("🔍 Decoding Error Details:")
                print(error)
                
                if let decodingError = error as? DecodingError {
                    switch decodingError {
                    case .keyNotFound(let key, let context):
                        print("❌ Clave no encontrada: '\(key.stringValue)'")
                        print("   Ruta: \(context.codingPath.map { $0.stringValue }.joined(separator: " -> "))")
                        print("   Descripción: \(context.debugDescription)")
                        
                    case .typeMismatch(let type, let context):
                        print("❌ Tipo incorrecto: Se esperaba '\(type)'")
                        print("   Ruta: \(context.codingPath.map { $0.stringValue }.joined(separator: " -> "))")
                        print("   Descripción: \(context.debugDescription)")
                        
                    case .valueNotFound(let type, let context):
                        print("❌ Valor no encontrado: Se esperaba '\(type)'")
                        print("   Ruta: \(context.codingPath.map { $0.stringValue }.joined(separator: " -> "))")
                        print("   Descripción: \(context.debugDescription)")
                        
                    case .dataCorrupted(let context):
                        print("❌ Datos corruptos")
                        print("   Ruta: \(context.codingPath.map { $0.stringValue }.joined(separator: " -> "))")
                        print("   Descripción: \(context.debugDescription)")
                        
                    @unknown default:
                        print("❌ Error de decodificación desconocido")
                    }
                }
                #endif
                
                throw NetworkError.decodingError
            }
        } catch let error as NetworkError {
            throw error
        } catch {
            throw NetworkError.unknown(error)
        }
    }
}
