import Foundation
import UIKit
import Vision

struct ExpiryDateRecognizer {
    static func recognize(in image: UIImage) async -> Date? {
        guard let cgImage = image.cgImage else { return nil }
        return await withCheckedContinuation { continuation in
            let request = VNRecognizeTextRequest { request, _ in
                let lines = (request.results as? [VNRecognizedTextObservation])?.compactMap { $0.topCandidates(1).first?.string } ?? []
                continuation.resume(returning: bestDate(from: lines.joined(separator: " ")))
            }
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = false
            request.recognitionLanguages = ["el-GR", "en-US"]
            DispatchQueue.global(qos: .userInitiated).async {
                try? VNImageRequestHandler(cgImage: cgImage, options: [:]).perform([request])
            }
        }
    }

    private static func bestDate(from raw: String) -> Date? {
        let text = raw.uppercased().replacingOccurrences(of: "O", with: "0")
        var candidates: [Date] = []
        let calendar = Calendar.current
        let nowYear = calendar.component(.year, from: .now)

        let fullPattern = #"\b(0?[1-9]|[12][0-9]|3[01])[\./-](0?[1-9]|1[0-2])[\./-]((?:20)?[0-9]{2})\b"#
        if let regex = try? NSRegularExpression(pattern: fullPattern) {
            for match in regex.matches(in: text, range: NSRange(text.startIndex..., in: text)) {
                guard let dR = Range(match.range(at: 1), in: text), let mR = Range(match.range(at: 2), in: text), let yR = Range(match.range(at: 3), in: text), let day = Int(text[dR]), let month = Int(text[mR]), var year = Int(text[yR]) else { continue }
                if year < 100 { year += 2000 }
                if let date = calendar.date(from: DateComponents(year: year, month: month, day: day)), year >= nowYear - 1, year <= nowYear + 20 { candidates.append(date) }
            }
        }

        let monthPattern = #"\b(0?[1-9]|1[0-2])[\./-]((?:20)?[0-9]{2})\b"#
        if let regex = try? NSRegularExpression(pattern: monthPattern) {
            for match in regex.matches(in: text, range: NSRange(text.startIndex..., in: text)) {
                guard let mR = Range(match.range(at: 1), in: text), let yR = Range(match.range(at: 2), in: text), let month = Int(text[mR]), var year = Int(text[yR]) else { continue }
                if year < 100 { year += 2000 }
                if year >= nowYear - 1, year <= nowYear + 20, let nextMonth = calendar.date(from: DateComponents(year: month == 12 ? year + 1 : year, month: month == 12 ? 1 : month + 1, day: 1)), let endOfMonth = calendar.date(byAdding: .day, value: -1, to: nextMonth) { candidates.append(endOfMonth) }
            }
        }
        return candidates.filter { $0 >= calendar.startOfDay(for: .now) }.sorted().first
    }
}