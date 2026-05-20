# 🔧 Troubleshooting - SpaceflightNews App

Soluciones a problemas comunes durante el desarrollo.

---

## ❌ Error: "fopen failed for data file: errno = 2"

### **Descripción**
```
fopen failed for data file: errno = 2 (No such file or directory)
Errors found! Invalidating cache...
```

### **Causa**
- URLSession está intentando acceder a directorios de cache que no existen
- El simulador o Xcode tienen cache corrupto
- Primera ejecución sin directorios inicializados

### **Impacto**
⚠️ **No crítico** - La app funciona normalmente, solo genera warnings en consola

---

### **Soluciones**

#### ✅ Solución 1: Limpiar Cache (Más rápido)

**Desde Terminal:**
```bash
# Cerrar Xcode completamente

# Limpiar DerivedData
rm -rf ~/Library/Developer/Xcode/DerivedData/*

# Limpiar cache del simulador
xcrun simctl delete unavailable

# Reabrir Xcode
```

**Desde Xcode:**
```
1. Product > Clean Build Folder (⇧⌘K)
2. Simulator > Device > Erase All Content and Settings...
3. Recompilar (⌘B)
```

---

#### ✅ Solución 2: Ya Implementada en el Código

El `NetworkService` ahora tiene configuración de cache mejorada:

```swift
static func createDefault() -> NetworkService {
    let configuration = URLSessionConfiguration.default
    
    #if DEBUG
    // En DEBUG: Sin cache para debugging
    configuration.requestCachePolicy = .reloadIgnoringLocalCacheData
    configuration.urlCache = nil
    #else
    // En RELEASE: Cache habilitado
    let cache = URLCache(memoryCapacity: 50_000_000, diskCapacity: 100_000_000)
    configuration.urlCache = cache
    #endif
    
    let session = URLSession(configuration: configuration)
    return NetworkService(session: session)
}
```

**Características:**
- ✅ En DEBUG: Sin cache de disco (evita errores)
- ✅ En RELEASE: Cache habilitado (mejor performance)
- ✅ Timeouts configurados (30s request, 5min resource)

---

#### ✅ Solución 3: Verificar Permisos del Simulador

```bash
# Verificar permisos del simulador
ls -la ~/Library/Developer/CoreSimulator/Devices/

# Si hay problemas, reiniciar el simulador
xcrun simctl shutdown all
xcrun simctl erase all
```

---

## ❌ Error: "No such module 'XCTest'"

### **Causa**
- El archivo de test está en el target principal en vez del target de tests

### **Solución**
```
1. Selecciona el archivo de test en el navegador
2. File Inspector (⌥⌘1)
3. Target Membership:
   ☐ SpaceflightNews (NO marcado)
   ☑ SpaceflightNewsTests (SÍ marcado)
```

---

## ❌ Error: "Cannot assign to property: 'state' setter is inaccessible"

### **Causa**
- Intentando modificar `@Published private(set) var state` desde tests

### **Solución**
Ya solucionado en `ArticleListViewModel.swift`:
```swift
@Published internal(set) var state: ArticleListState = .idle
```

---

## ❌ Error: Rate Limiting o 429 Too Many Requests

### **Causa**
- Demasiadas requests a la API en poco tiempo

### **Solución Implementada**
Debounce en búsqueda:
```swift
$searchQuery
    .debounce(for: .milliseconds(500), scheduler: DispatchQueue.main)
    .removeDuplicates()
    .sink { [weak self] query in
        // ...
    }
```

### **Mejora Adicional: Rate Limiter**

```swift
actor RateLimiter {
    private var lastRequestTime: Date?
    private let minimumInterval: TimeInterval = 0.5 // 500ms entre requests
    
    func shouldAllowRequest() async -> Bool {
        guard let lastTime = lastRequestTime else {
            lastRequestTime = Date()
            return true
        }
        
        let elapsed = Date().timeIntervalSince(lastTime)
        if elapsed >= minimumInterval {
            lastRequestTime = Date()
            return true
        }
        
        return false
    }
}
```

---

## ❌ Error: Decodificación JSON Fallando

### **Síntomas**
```
NetworkError.decodingError
```

### **Causa**
- La API cambió su estructura
- Campos opcionales no manejados

### **Solución: Logging de Errores**

```swift
// En NetworkService.request()
do {
    let decodedData = try decoder.decode(T.self, from: data)
    return decodedData
} catch {
    #if DEBUG
    // Log del JSON crudo para debugging
    if let jsonString = String(data: data, encoding: .utf8) {
        print("❌ Decoding error. JSON response:")
        print(jsonString)
    }
    print("❌ Decoding error details: \(error)")
    #endif
    throw NetworkError.decodingError
}
```

---

## ❌ Error: Memory Leaks en Combine

### **Causa**
- No usar `[weak self]` en closures
- No cancelar suscripciones

### **Solución Implementada**
```swift
$searchQuery
    .debounce(for: .milliseconds(500), scheduler: DispatchQueue.main)
    .removeDuplicates()
    .sink { [weak self] query in  // ✅ weak self
        Task {
            await self?.performSearch(query: query)
        }
    }
    .store(in: &cancellables)  // ✅ Almacenado para cancelación
```

---

## ❌ Error: Imágenes No Cargan

### **Síntomas**
- `AsyncImage` muestra placeholder siempre

### **Posibles Causas**
1. URL inválida
2. HTTP en vez de HTTPS
3. Problemas de red

### **Solución: Verificación de URLs**

```swift
struct ArticleRowView: View {
    let article: Article
    
    var body: some View {
        AsyncImage(url: URL(string: article.imageURL)) { phase in
            switch phase {
            case .empty:
                ProgressView()
            case .success(let image):
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            case .failure(let error):
                VStack {
                    Image(systemName: "photo")
                    #if DEBUG
                    Text("Error: \(error.localizedDescription)")
                        .font(.caption2)
                    #endif
                }
            @unknown default:
                EmptyView()
            }
        }
    }
}
```

---

## ❌ Error: App Crashes en Background

### **Causa**
- Network requests en background sin manejo adecuado

### **Solución**
```swift
func loadArticles() async {
    // Verificar que estamos en Main Actor
    guard !Task.isCancelled else { return }
    
    state = .loading
    
    do {
        let articles = try await repository.fetchArticles(limit: 50, offset: 0)
        
        // Verificar nuevamente antes de actualizar UI
        guard !Task.isCancelled else { return }
        handleLoadedArticles(articles)
    } catch {
        guard !Task.isCancelled else { return }
        state = .error(error.localizedDescription)
    }
}
```

---

## 🧪 Testing Issues

### **Tests Fallan por Timing**

```swift
func testSearchWithEmptyQueryLoadsAllArticles() async {
    let viewModel = ArticleListViewModel(repository: MockSuccessRepository())
    
    viewModel.searchQuery = ""
    
    // Esperar SUFICIENTE tiempo para el debounce
    try? await Task.sleep(for: .milliseconds(600))  // 500ms debounce + 100ms buffer
    
    // Verificar estado...
}
```

### **Mock Repositories Inconsistentes**

```swift
private final class MockSuccessRepository: ArticleRepositoryProtocol {
    // ✅ Implementar TODOS los métodos del protocolo
    func fetchArticles(limit: Int, offset: Int) async throws -> [Article] {
        Article.mocks
    }
    
    func fetchArticles(filters: ArticleFilters) async throws -> [Article] {
        Article.mocks
    }
    
    func searchArticles(query: String, limit: Int) async throws -> [Article] {
        Article.mocks.filter { $0.title.localizedCaseInsensitiveContains(query) }
    }
    
    func fetchArticle(id: Int) async throws -> Article {
        Article.mock
    }
}
```

---

## 🔍 Debugging Tips

### **1. Habilitar Network Logging**

```swift
// En NetworkService
func request<T: Decodable>(_ endpoint: APIEndpoint) async throws -> T {
    guard let url = endpoint.url else {
        throw NetworkError.invalidURL
    }
    
    #if DEBUG
    print("📡 Request: \(endpoint.method.rawValue) \(url.absoluteString)")
    #endif
    
    // ...resto del código
}
```

### **2. Instrumentos útiles**

```bash
# Network debugging
instruments -t "Network" -D trace.trace MyApp.app

# Memory leaks
instruments -t "Leaks" -D leaks.trace MyApp.app
```

### **3. Breakpoints Simbólicos**

En Xcode:
```
Breakpoint Navigator > + > Symbolic Breakpoint
Symbol: URLSession:task:didCompleteWithError:
```

---

## 📊 Performance Tips

### **1. Limitar Frecuencia de Búsqueda**

Ya implementado con debounce de 500ms ✅

### **2. Cache de Imágenes**

AsyncImage ya tiene cache básico, pero puedes mejorar:

```swift
import Kingfisher

// Reemplazar AsyncImage con:
KFImage(URL(string: article.imageURL))
    .placeholder {
        ProgressView()
    }
    .retry(maxCount: 3, interval: .seconds(2))
    .cacheMemoryOnly()
```

### **3. Paginación**

Ver `EXAMPLES.md` para implementación completa de paginación infinita.

---

## 🆘 Última Opción: Reset Completo

Si nada funciona:

```bash
# 1. Cerrar Xcode completamente

# 2. Limpiar TODO
rm -rf ~/Library/Developer/Xcode/DerivedData/*
rm -rf ~/Library/Caches/com.apple.dt.Xcode
xcrun simctl delete unavailable
xcrun simctl shutdown all

# 3. Reinstalar dependencias (si usas SPM)
# En el proyecto:
# File > Packages > Reset Package Caches

# 4. Clean build
# Product > Clean Build Folder (⇧⌘K)

# 5. Rebuild
# ⌘B
```

---

## 📞 Necesitas Más Ayuda?

1. Revisa los logs completos en Console.app
2. Verifica la documentación de la API: `API_DOCUMENTATION.md`
3. Consulta ejemplos: `EXAMPLES.md`
4. Busca issues similares en el repo de la API: https://github.com/TheSpaceDevs/spaceflightnewsapi

---

**Última actualización:** Mayo 2026
