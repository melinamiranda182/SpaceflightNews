# 🔍 Guía de Debugging - Errores de Decodificación

## 🎯 Problema: "Error al procesar los datos"

Cuando ves este mensaje, significa que el JSON de la API no coincide con tu `ArticleDTO`.

---

## ✅ **Soluciones Implementadas**

### 1. **Logging Detallado** ⭐

El `NetworkService` ahora imprime información completa cuando falla la decodificación:

```swift
❌ DECODING ERROR:
📍 URL: https://api.spaceflightnewsapi.net/v4/articles/...
📦 Response Status: 200
📄 JSON Response:
{...el JSON real de la API...}
🔍 Decoding Error Details:
❌ Clave no encontrada: 'featured'
   Ruta: results -> 0 -> featured
   Descripción: ...
```

**Cómo usarlo:**
1. Ejecuta la app (⌘R)
2. Reproduce el error
3. Ve a la **consola de Xcode** (⇧⌘Y)
4. Busca `❌ DECODING ERROR`
5. Lee el JSON y el error específico

---

### 2. **Campos Opcionales**

Todos los campos que pueden venir como `null` o faltar ahora son opcionales:

```swift
struct ArticleDTO: Decodable {
    // Campos requeridos
    let id: Int
    let title: String
    let url: String
    let newsSite: String
    let summary: String
    let publishedAt: String
    let updatedAt: String
    
    // Campos opcionales (pueden ser null)
    let imageUrl: String?      // ✅ Puede ser null
    let featured: Bool?        // ✅ Puede ser null
    let launches: [LaunchDTO]? // ✅ Puede ser null o faltar
    let events: [EventDTO]?    // ✅ Puede ser null o faltar
}
```

---

### 3. **Parsing de Fechas Robusto**

El formatter ahora intenta múltiples formatos:

```swift
private static let dateFormatter: ISO8601DateFormatter = {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    return formatter
}()

private static let fallbackDateFormatter: ISO8601DateFormatter = {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime]
    return formatter
}()

// Intenta con ambos formatos
guard let published = Self.dateFormatter.date(from: publishedAt) 
        ?? Self.fallbackDateFormatter.date(from: publishedAt) else {
    return nil
}
```

**Formatos soportados:**
- ✅ `2026-05-19T10:00:00Z`
- ✅ `2026-05-19T10:00:00.123Z` (con milisegundos)
- ✅ `2026-05-19T10:00:00+00:00`

---

### 4. **Valores por Defecto Seguros**

```swift
return Article(
    id: id,
    title: title,
    url: url,
    imageURL: imageUrl ?? "",             // ✅ String vacío si es null
    newsSite: newsSite,
    summary: summary,
    publishedAt: published,
    updatedAt: updated,
    featured: featured ?? false,          // ✅ false por defecto
    hasLaunches: !(launches?.isEmpty ?? true),  // ✅ false si nil o vacío
    hasEvents: !(events?.isEmpty ?? true)       // ✅ false si nil o vacío
)
```

---

## 🔧 **Cómo Debuggear un Error de Decodificación**

### **Paso 1: Ver el Error Completo**

Ejecuta la app y busca en consola:

```
❌ DECODING ERROR:
```

### **Paso 2: Identificar el Campo Problemático**

```
❌ Clave no encontrada: 'image_url'
   Ruta: results -> 0 -> image_url
```

Esto significa:
- El campo `image_url` no existe en `results[0]`
- O está escrito diferente en la API

### **Paso 3: Ver el JSON Real**

```json
📄 JSON Response:
{
  "count": 100,
  "results": [
    {
      "id": 1,
      "title": "...",
      "imageUrl": "..."  ← ❌ Está en camelCase, no snake_case!
    }
  ]
}
```

### **Paso 4: Ajustar el CodingKeys**

```swift
enum CodingKeys: String, CodingKey {
    case imageUrl = "image_url"  // ← Si la API usa snake_case
    // O
    case imageUrl                 // ← Si la API usa camelCase
}
```

---

## 🧪 **Tests Agregados**

### Test de Campos Null

```swift
func testArticleDTOWithNullOptionalFields() {
    let dto = ArticleDTO(
        id: 1,
        title: "Test",
        url: "https://example.com",
        imageUrl: nil,    // ✨ Testing null
        newsSite: "Test",
        summary: "Test",
        publishedAt: "2026-05-19T10:00:00Z",
        updatedAt: "2026-05-19T10:00:00Z",
        featured: nil,    // ✨ Testing null
        launches: nil,    // ✨ Testing null
        events: nil       // ✨ Testing null
    )
    
    let article = dto.toDomain()
    
    XCTAssertNotNil(article)
    XCTAssertEqual(article?.imageURL, "")  // Default
    XCTAssertEqual(article?.featured, false)
}
```

Ejecuta tests: `⌘U`

---

## 📊 **Errores Comunes y Soluciones**

### **Error: keyNotFound**

```
❌ Clave no encontrada: 'featured'
```

**Causa:** El campo no existe en la respuesta JSON.

**Solución:**
```swift
let featured: Bool?  // ✅ Hacer opcional
```

---

### **Error: typeMismatch**

```
❌ Tipo incorrecto: Se esperaba 'String', pero se recibió 'Int'
```

**Causa:** El tipo no coincide.

**Solución:**
```swift
// Si la API envía Int pero esperabas String:
let id: Int  // ✅ Cambiar el tipo

// O crear un Decodable custom:
struct FlexibleString: Decodable {
    let value: String
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let intValue = try? container.decode(Int.self) {
            value = String(intValue)
        } else {
            value = try container.decode(String.self)
        }
    }
}
```

---

### **Error: valueNotFound**

```
❌ Valor no encontrado: Se esperaba 'String'
```

**Causa:** El campo existe pero es `null`.

**Solución:**
```swift
let imageUrl: String?  // ✅ Hacer opcional
```

---

### **Error: dataCorrupted**

```
❌ Datos corruptos: Invalid date format
```

**Causa:** La fecha no está en el formato esperado.

**Solución:** Ya implementado con múltiples formatters.

---

## 🎯 **Ejemplo Real de Debugging**

### Escenario: La API cambió `image_url` por `imageUrl`

**1. Ver el error:**
```
❌ Clave no encontrada: 'image_url'
📄 JSON Response:
{
  "imageUrl": "https://..."  ← Está en camelCase!
}
```

**2. Solución:**
```swift
enum CodingKeys: String, CodingKey {
    case imageUrl  // ← Remover el = "image_url"
}
```

**3. O si quieres soportar ambos:**
```swift
struct ArticleDTO: Decodable {
    let imageUrl: String?
    
    enum CodingKeys: String, CodingKey {
        case imageUrl = "image_url"
        case imageUrlCamelCase = "imageUrl"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Intentar snake_case primero, luego camelCase
        imageUrl = try container.decodeIfPresent(String.self, forKey: .imageUrl)
            ?? container.decodeIfPresent(String.self, forKey: .imageUrlCamelCase)
        
        // ... resto de campos
    }
}
```

---

## 🚀 **Prueba en Tiempo Real**

### **Usando curl:**

```bash
curl -X GET "https://api.spaceflightnewsapi.net/v4/articles/?limit=1" \
  -H "Accept: application/json" | jq
```

Esto te muestra exactamente qué devuelve la API.

### **Usando Postman:**

1. GET `https://api.spaceflightnewsapi.net/v4/articles/?limit=1`
2. Copia el JSON
3. Compara con tu `ArticleDTO`

---

## 📝 **Checklist de Verificación**

Antes de hacer cambios, verifica:

- [ ] ¿El campo existe en la respuesta JSON real?
- [ ] ¿El tipo coincide? (String vs Int, etc.)
- [ ] ¿El nombre coincide? (snake_case vs camelCase)
- [ ] ¿Puede ser null? → Hacer opcional
- [ ] ¿Es un array? → ¿Puede estar vacío?
- [ ] ¿Es una fecha? → ¿Qué formato usa?

---

## 🆘 **Si Nada Funciona**

1. **Copiar el JSON real de la consola**
2. **Usar quicktype.io** para generar el DTO automáticamente:
   - Ve a https://app.quicktype.io/
   - Pega el JSON
   - Selecciona "Swift" y "Just Types"
   - Copia el resultado

3. **Comparar** con tu `ArticleDTO` actual

---

## 📊 **Herramientas Útiles**

### **1. JSON Formatter**
```bash
# Formatear JSON de la consola
echo '{...}' | jq .
```

### **2. Swift REPL**
```bash
swift
```

```swift
import Foundation

let json = """
{"id": 1, "title": "Test"}
"""

struct Test: Decodable {
    let id: Int
    let title: String
}

let data = json.data(using: .utf8)!
let decoded = try JSONDecoder().decode(Test.self, from: data)
print(decoded)
```

---

## ✅ **Verificación Final**

Después de los cambios, ejecuta:

```bash
# 1. Limpiar build
⇧⌘K

# 2. Ejecutar tests
⌘U

# 3. Ejecutar app
⌘R

# 4. Verificar consola
# NO deberías ver:
# ❌ DECODING ERROR
# ✅ Error al procesar los datos
```

---

**¿Sigue sin funcionar?** Comparte:
1. El output completo de `❌ DECODING ERROR` de la consola
2. La URL que está fallando
3. El JSON completo de la respuesta

---

**Última actualización:** Mayo 2026
