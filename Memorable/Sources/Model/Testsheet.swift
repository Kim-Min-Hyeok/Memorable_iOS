//
//  Testsheet.swift
//  Memorable
//
//  Created by Minhyeok Kim on 7/3/24.
//

import Foundation

struct Testsheet: Document, Codable {
    let id: Int
    let name: String
    let category: String
    var isBookmarked: Bool
    let createdDate: Date
    var fileType: String = "나만의 시험지"

    enum CodingKeys: String, CodingKey {
        case id = "testsheetId"
        case name
        case category
        case isBookmarked = "testsheetBookmark"
        case createdDate = "testsheetCreateDate" // Change this line
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        name = try container.decodeIfPresent(String.self, forKey: .name) ?? "나만의 시험지"
        category = try container.decode(String.self, forKey: .category)
        isBookmarked = try container.decode(Bool.self, forKey: .isBookmarked)

        let dateString = try container.decode(String.self, forKey: .createdDate)

        // DateFormatter를 사용한 파싱 시도
        let dateFormatters: [DateFormatter] = [
            {
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSS"
                return formatter
            }(),
            {
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
                return formatter
            }()
        ]

        for formatter in dateFormatters {
            if let date = formatter.date(from: dateString) {
                createdDate = date
                return
            }
        }

        // ISO8601DateFormatter를 사용한 파싱 시도
        let iso8601Formatter = ISO8601DateFormatter()
        iso8601Formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = iso8601Formatter.date(from: dateString) {
            createdDate = date
            return
        }

        // 모든 형식이 실패하면 오류를 던집니다.
        throw DecodingError.dataCorruptedError(forKey: .createdDate, in: container, debugDescription: "Date string does not match any known format: \(dateString)")
    }
}

struct TestsheetDetail: Codable {
    let testsheetId: Int
    let name: String
    let category: String
    var reExtracted: Bool
    var isCompleteAllBlanks: [Bool]
    var questions1: [Question]
    var questions2: [Question]
    var score: [Int]?
    var isCorrect: [Bool]?

    enum CodingKeys: String, CodingKey {
        case testsheetId, name, category, reExtracted, isCompleteAllBlanks, questions1, questions2, score, isCorrect
    }
}

// 채점 결과
struct TestsheetGrade: Codable {
    let score: [Int]?
    let isCorrect: [Bool]?
    
    private struct DynamicCodingKeys: CodingKey {
        var stringValue: String
        init?(stringValue: String) {
            self.stringValue = stringValue
        }
        var intValue: Int?
        init?(intValue: Int) {
            return nil
        }
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: DynamicCodingKeys.self)
        score = try container.decodeIfPresent([Int].self, forKey: DynamicCodingKeys(stringValue: "score")!)
        isCorrect = try container.decodeIfPresent([Bool].self, forKey: DynamicCodingKeys(stringValue: "isCorrect")!)
    }
}
