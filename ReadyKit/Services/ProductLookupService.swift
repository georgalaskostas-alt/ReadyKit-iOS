import Foundation

struct ProductLookupResult: Sendable {
    let name: String
    let brand: String?
    let quantityText: String?
    let imageURL: URL?
    let caloriesPer100g: Double?
    let productQuantity: Double?
    let productQuantityUnit: String?
    let categories: String?

    var isWater: Bool {
        let text = "\(name) \(categories ?? "")".lowercased()
        let waterWords = ["water", "mineral water", "spring water", "νερό", "μεταλλικό νερό", "eau minérale", "agua mineral"]
        return waterWords.contains { text.contains($0) }
    }

    var packageLiters: Double? {
        guard isWater else { return nil }
        if let amount = productQuantity, let unit = productQuantityUnit?.lowercased() {
            if ["l", "liter", "litre", "liters", "litres"].contains(unit) { return amount }
            if ["ml", "milliliter", "millilitre"].contains(unit) { return amount / 1000 }
            if ["cl"].contains(unit) { return amount / 100 }
        }
        guard let q = quantityText?.lowercased().replacingOccurrences(of: ",", with: ".") else { return nil }
        let pattern = #"([0-9]+(?:\.[0-9]+)?)\s*(ml|cl|l)\b"#
        guard let regex = try? NSRegularExpression(pattern: pattern), let match = regex.firstMatch(in: q, range: NSRange(q.startIndex..., in: q)), let numberRange = Range(match.range(at: 1), in: q), let unitRange = Range(match.range(at: 2), in: q), let number = Double(q[numberRange]) else { return nil }
        switch String(q[unitRange]) { case "ml": return number / 1000; case "cl": return number / 100; default: return number }
    }

    var packageCalories: Double? {
        guard let kcal = caloriesPer100g, let amount = productQuantity, let unit = productQuantityUnit?.lowercased() else { return nil }
        if unit == "g" { return kcal * amount / 100 }
        if unit == "kg" { return kcal * amount * 10 }
        return nil
    }
}

enum ProductLookupError: LocalizedError { case invalidBarcode, notFound, invalidResponse
    var errorDescription: String? { switch self { case .invalidBarcode: return "Invalid barcode"; case .notFound: return "Product not found"; case .invalidResponse: return "Invalid product response" } }
}

actor ProductLookupService {
    static let shared = ProductLookupService()
    private struct Response: Decodable { let status: Int?; let product: Product? }
    private struct Product: Decodable {
        let productName: String?; let brands: String?; let quantity: String?; let imageFrontURL: String?; let imageURL: String?; let productQuantity: Double?; let productQuantityUnit: String?; let categories: String?; let nutriments: Nutriments?
        enum CodingKeys: String, CodingKey { case productName = "product_name"; case brands, quantity; case imageFrontURL = "image_front_url"; case imageURL = "image_url"; case productQuantity = "product_quantity"; case productQuantityUnit = "product_quantity_unit"; case categories, nutriments }
    }
    private struct Nutriments: Decodable { let energyKcal100g: Double?; enum CodingKeys: String, CodingKey { case energyKcal100g = "energy-kcal_100g" } }

    func lookup(barcode rawBarcode: String) async throws -> ProductLookupResult {
        let barcode = rawBarcode.filter(\.isNumber); guard !barcode.isEmpty else { throw ProductLookupError.invalidBarcode }
        var components = URLComponents(string: "https://world.openfoodfacts.org/api/v2/product/\(barcode).json")!
        components.queryItems = [URLQueryItem(name: "fields", value: "product_name,brands,quantity,image_front_url,image_url,product_quantity,product_quantity_unit,categories,nutriments")]
        guard let url = components.url else { throw ProductLookupError.invalidBarcode }
        var request = URLRequest(url: url); request.timeoutInterval = 12; request.setValue("ReadyKit/1.0 (iOS; barcode product lookup)", forHTTPHeaderField: "User-Agent")
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else { throw ProductLookupError.invalidResponse }
        let decoded = try JSONDecoder().decode(Response.self, from: data); guard decoded.status == 1, let product = decoded.product else { throw ProductLookupError.notFound }
        let productName = product.productName?.trimmingCharacters(in: .whitespacesAndNewlines); let brand = product.brands?.trimmingCharacters(in: .whitespacesAndNewlines)
        let resolvedName: String
        if let productName, !productName.isEmpty { resolvedName = productName } else if let brand, !brand.isEmpty { resolvedName = brand } else { throw ProductLookupError.notFound }
        let imageString = product.imageFrontURL ?? product.imageURL
        return ProductLookupResult(name: resolvedName, brand: brand?.isEmpty == false ? brand : nil, quantityText: product.quantity, imageURL: imageString.flatMap(URL.init(string:)), caloriesPer100g: product.nutriments?.energyKcal100g, productQuantity: product.productQuantity, productQuantityUnit: product.productQuantityUnit, categories: product.categories)
    }

    func downloadImage(from url: URL) async -> Data? {
        var request = URLRequest(url: url); request.timeoutInterval = 12; request.setValue("ReadyKit/1.0 (iOS; product image)", forHTTPHeaderField: "User-Agent")
        guard let (data, response) = try? await URLSession.shared.data(for: request), let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode), !data.isEmpty, data.count <= 8_000_000 else { return nil }
        return data
    }
}