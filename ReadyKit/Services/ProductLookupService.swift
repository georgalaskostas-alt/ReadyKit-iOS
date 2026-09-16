import Foundation

struct ProductLookupResult: Sendable {
    let name: String
    let brand: String?
    let quantityText: String?
    let imageURL: URL?
    let caloriesPer100g: Double?
    let productQuantity: Double?
    let productQuantityUnit: String?
}

enum ProductLookupError: LocalizedError {
    case invalidBarcode
    case notFound
    case invalidResponse

    var errorDescription: String? {
        switch self {
        case .invalidBarcode: return "Invalid barcode"
        case .notFound: return "Product not found"
        case .invalidResponse: return "Invalid product response"
        }
    }
}

actor ProductLookupService {
    static let shared = ProductLookupService()

    private struct Response: Decodable {
        let status: Int?
        let product: Product?
    }

    private struct Product: Decodable {
        let productName: String?
        let brands: String?
        let quantity: String?
        let imageFrontURL: String?
        let imageURL: String?
        let productQuantity: Double?
        let productQuantityUnit: String?
        let nutriments: Nutriments?

        enum CodingKeys: String, CodingKey {
            case productName = "product_name"
            case brands, quantity
            case imageFrontURL = "image_front_url"
            case imageURL = "image_url"
            case productQuantity = "product_quantity"
            case productQuantityUnit = "product_quantity_unit"
            case nutriments
        }
    }

    private struct Nutriments: Decodable {
        let energyKcal100g: Double?

        enum CodingKeys: String, CodingKey {
            case energyKcal100g = "energy-kcal_100g"
        }
    }

    func lookup(barcode rawBarcode: String) async throws -> ProductLookupResult {
        let barcode = rawBarcode.filter(\.isNumber)
        guard !barcode.isEmpty else { throw ProductLookupError.invalidBarcode }

        var components = URLComponents(string: "https://world.openfoodfacts.org/api/v2/product/\(barcode).json")!
        components.queryItems = [
            URLQueryItem(name: "fields", value: "product_name,brands,quantity,image_front_url,image_url,product_quantity,product_quantity_unit,nutriments")
        ]
        guard let url = components.url else { throw ProductLookupError.invalidBarcode }

        var request = URLRequest(url: url)
        request.timeoutInterval = 12
        request.setValue("ReadyKit/1.0 (iOS; barcode product lookup)", forHTTPHeaderField: "User-Agent")

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw ProductLookupError.invalidResponse
        }

        let decoded = try JSONDecoder().decode(Response.self, from: data)
        guard decoded.status == 1, let product = decoded.product else {
            throw ProductLookupError.notFound
        }

        let productName = product.productName?.trimmingCharacters(in: .whitespacesAndNewlines)
        let brand = product.brands?.trimmingCharacters(in: .whitespacesAndNewlines)
        let resolvedName: String
        if let productName, !productName.isEmpty {
            resolvedName = productName
        } else if let brand, !brand.isEmpty {
            resolvedName = brand
        } else {
            throw ProductLookupError.notFound
        }

        let imageString = product.imageFrontURL ?? product.imageURL
        return ProductLookupResult(
            name: resolvedName,
            brand: brand?.isEmpty == false ? brand : nil,
            quantityText: product.quantity,
            imageURL: imageString.flatMap(URL.init(string:)),
            caloriesPer100g: product.nutriments?.energyKcal100g,
            productQuantity: product.productQuantity,
            productQuantityUnit: product.productQuantityUnit
        )
    }

    func downloadImage(from url: URL) async -> Data? {
        var request = URLRequest(url: url)
        request.timeoutInterval = 12
        request.setValue("ReadyKit/1.0 (iOS; product image)", forHTTPHeaderField: "User-Agent")
        guard let (data, response) = try? await URLSession.shared.data(for: request),
              let http = response as? HTTPURLResponse,
              (200...299).contains(http.statusCode),
              !data.isEmpty else { return nil }
        return data
    }
}
