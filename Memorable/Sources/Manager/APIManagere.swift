//
//  APIManagere.swift
//  Memorable
//
//  Created by Minhyeok Kim on 7/3/24.
//

import Foundation

enum APIError: Error {
    case invalidURL
    case networkError(Error)
    case decodingError(Error)
    case serverError(statusCode: Int, message: String)
}

class APIManagere {
    static let shared = APIManagere()
    private let baseURL = "http://172.30.1.26:8080"
        
    struct EmptyResponse: Codable {}
        
    private init() {}
        
    // MARK: - Worksheet
        
    // 1. 빈칸 학습지 간략 정보 불러오기
    func getWorksheets(userId: String, completion: @escaping (Result<[Worksheet], Error>) -> Void) {
        let urlString = "\(baseURL)/api/worksheet/user/\(userId)"
        print("Requesting worksheets from: \(urlString)")
        
        guard let url = URL(string: urlString) else {
            print("Invalid URL: \(urlString)")
            completion(.failure(APIError.invalidURL))
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                print("Network error: \(error.localizedDescription)")
                completion(.failure(APIError.networkError(error)))
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                print("HTTP Status Code: \(httpResponse.statusCode)")
                
                // Check for non-200 status codes
                guard (200...299).contains(httpResponse.statusCode) else {
                    print("Server error with status code: \(httpResponse.statusCode)")
                    completion(.failure(APIError.serverError(statusCode: httpResponse.statusCode, message: "Server error")))
                    return
                }
            }
            
            guard let data = data else {
                print("No data received")
                completion(.failure(APIError.serverError(statusCode: 0, message: "No data received")))
                return
            }
            
            print("Received data: \(String(data: data, encoding: .utf8) ?? "Unable to convert data to string")")
            
            do {
                let worksheets = try JSONDecoder().decode([Worksheet].self, from: data)
                print("Successfully decoded \(worksheets.count) worksheets")
                completion(.success(worksheets))
            } catch {
                print("Decoding error: \(error)")
                if let decodingError = error as? DecodingError {
                    switch decodingError {
                    case .keyNotFound(let key, let context):
                        print("Key '\(key)' not found: \(context.debugDescription)")
                    case .valueNotFound(let value, let context):
                        print("Value '\(value)' not found: \(context.debugDescription)")
                    case .typeMismatch(let type, let context):
                        print("Type '\(type)' mismatch: \(context.debugDescription)")
                    case .dataCorrupted(let context):
                        print("Data corrupted: \(context.debugDescription)")
                    @unknown default:
                        print("Unknown decoding error")
                    }
                }
                completion(.failure(APIError.decodingError(error)))
            }
        }.resume()
    }
        
    // 2. 빈칸 학습지 텍스트, 정답 불러오기
    func getWorksheet(worksheetId: Int, completion: @escaping (Result<WorksheetDetail, Error>) -> Void) {
        let urlString = "\(baseURL)/api/worksheet/ws/\(worksheetId)"
        
        guard let url = URL(string: urlString) else {
            completion(.failure(NSError(domain: "Invalid URL", code: 0, userInfo: nil)))
            return
        }
        
        let task = URLSession.shared.dataTask(with: url) { data, _, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(NSError(domain: "No data received", code: 0, userInfo: nil)))
                return
            }
            
            do {
                let decoder = JSONDecoder()
                let worksheetDetail = try decoder.decode(WorksheetDetail.self, from: data)
                
                completion(.success(worksheetDetail))
            } catch {
                completion(.failure(error))
            }
        }
        
        task.resume()
    }
    
    // 3. 가장 최근에 이용한 빈칸학습지 불러오기
    func getMostRecentWorksheet(userId: String, completion: @escaping (Result<WorksheetDetail, Error>) -> Void) {
        let urlString = "\(baseURL)/api/worksheet/recentDate/\(userId)"
        
        guard let url = URL(string: urlString) else {
            completion(.failure(NSError(domain: "Invalid URL", code: 0, userInfo: nil)))
            return
        }
        
        let task = URLSession.shared.dataTask(with: url) { (data, response, error) in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(NSError(domain: "No data received", code: 0, userInfo: nil)))
                return
            }
            
            do {
                let decoder = JSONDecoder()
                let worksheetDetail = try decoder.decode(WorksheetDetail.self, from: data)
                completion(.success(worksheetDetail))
            } catch {
                completion(.failure(error))
            }
        }
        
        task.resume()
    }
    
    // 4. 학습지 생성
    func createWorksheet(userId: String, name: String, category: String, content: String, completion: @escaping (Result<WorksheetDetail, Error>) -> Void) {
        let urlString = "\(baseURL)/api/worksheet"
        guard let url = URL(string: urlString) else {
            completion(.failure(APIError.invalidURL))
            return
        }
        
        let body: [String: Any] = [
            "userId": userId,
            "name": name,
            "category": category,
            "content": content
        ]
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        } catch {
            completion(.failure(error))
            return
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(APIError.networkError(error)))
                return
            }
            
            guard let data = data else {
                completion(.failure(APIError.serverError(statusCode: 0, message: "No data received")))
                return
            }
            
            do {
                let worksheetDetail = try JSONDecoder().decode(WorksheetDetail.self, from: data)
                completion(.success(worksheetDetail))
            } catch {
                completion(.failure(APIError.decodingError(error)))
            }
        }.resume()
    }
    
    // 5. 즐겨찾기 토글 기능
    func toggleWorksheetBookmark(worksheetId: Int, completion: @escaping (Result<Worksheet, Error>) -> Void) {
        let urlString = "\(baseURL)/api/worksheet/\(worksheetId)"
        guard let url = URL(string: urlString) else {
            completion(.failure(NSError(domain: "Invalid URL", code: 0, userInfo: nil)))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(NSError(domain: "No data received", code: 0, userInfo: nil)))
                return
            }
            
            do {
                let worksheet = try JSONDecoder().decode(Worksheet.self, from: data)
                completion(.success(worksheet))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
    
    // 6. 빈칸학습지 마지막 이용 시간 서버에 Patch
    func updateWorksheetRecentDate(worksheetId: Int, completion: @escaping (Result<Void, Error>) -> Void) {
        let urlString = "\(baseURL)/api/worksheet/recentDate/\(worksheetId)"
        
        guard let url = URL(string: urlString) else {
            completion(.failure(NSError(domain: "Invalid URL", code: 0, userInfo: nil)))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let task = URLSession.shared.dataTask(with: request) { _, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode)
            else {
                completion(.failure(NSError(domain: "Invalid response", code: 0, userInfo: nil)))
                return
            }
            
            completion(.success(()))
        }
        
        task.resume()
    }
        
        func deleteWorksheet(worksheetId: Int, completion: @escaping (Result<EmptyResponse, Error>) -> Void) {
            let urlString = "\(baseURL)/api/worksheet/\(worksheetId)"
            performRequest(urlString: urlString, method: "DELETE", completion: completion)
        }
    
    // MARK: - Testsheet
    
    func getTestsheets(userId: String, completion: @escaping (Result<[Testsheet], Error>) -> Void) {
        // Mock data 사용
        completion(.success(getMockTestsheets()))
    }
    
    func getTestsheet(testsheetId: Int, completion: @escaping (Result<TestsheetDetail, Error>) -> Void) {
        // Mock data 사용
        completion(.success(getMockTestsheetDetail()))
    }
    
    func createTestsheet(worksheetId: Int, completion: @escaping (Result<TestsheetDetail, Error>) -> Void) {
        // Mock data 사용
        completion(.success(getMockTestsheetDetail()))
    }
    
    func updateTestsheet(testsheetId: Int, userAnswers1: [String], userAnswers2: [String], completion: @escaping (Result<TestsheetDetail, Error>) -> Void) {
        // Mock data 사용
        completion(.success(getMockTestsheetDetail()))
    }
    
    func toggleTestsheetBookmark(testsheetId: Int, completion: @escaping (Result<Testsheet, Error>) -> Void) {
        // Mock data 사용
        completion(.success(getMockTestsheets().first!))
    }
    
    func deleteTestsheet(testsheetId: Int, completion: @escaping (Result<EmptyResponse, Error>) -> Void) {
        // Mock data 사용
        completion(.success(EmptyResponse()))
    }
    
    // MARK: - Wrongsheet
    
    func getWrongsheets(userId: String, completion: @escaping (Result<[Wrongsheet], Error>) -> Void) {
        // Mock data 사용
        completion(.success(getMockWrongsheets()))
    }
    
    func getWrongsheet(wrongsheetId: Int, completion: @escaping (Result<WrongsheetDetail, Error>) -> Void) {
        // Mock data 사용
        completion(.success(getMockWrongsheetDetail()))
    }
    
    func createWrongsheet(questions: [[String: Any]], completion: @escaping (Result<WrongsheetDetail, Error>) -> Void) {
        // Mock data 사용
        completion(.success(getMockWrongsheetDetail()))
    }
    
    func toggleWrongsheetBookmark(wrongsheetId: Int, completion: @escaping (Result<Wrongsheet, Error>) -> Void) {
        // Mock data 사용
        completion(.success(getMockWrongsheets().first!))
    }
    
    func deleteWrongsheet(wrongsheetId: Int, completion: @escaping (Result<EmptyResponse, Error>) -> Void) {
        // Mock data 사용
        completion(.success(EmptyResponse()))
    }
    
    // MARK: - Helper Methods
    
    private func performRequest<T: Codable>(urlString: String, method: String = "GET", body: [String: Any]? = nil, completion: @escaping (Result<T, Error>) -> Void) {
        // 이 메서드는 mock 데이터를 사용하는 시점에서 필요 없습니다.
    }
    
    private func performRequestWithoutResponse(urlString: String, method: String, completion: @escaping (Result<Void, Error>) -> Void) {
        // 이 메서드는 mock 데이터를 사용하는 시점에서 필요 없습니다.
    }
    
    func getDocuments(userId: String, completion: @escaping (Result<[Document], Error>) -> Void) {
        let group = DispatchGroup()
        var documents: [Document] = []
        var error: Error?
        
        group.enter()
        getWorksheets(userId: userId) { result in
            switch result {
            case .success(let worksheets):
                documents.append(contentsOf: worksheets)
            case .failure(let err):
                error = err
            }
            group.leave()
        }
        
        group.enter()
        getTestsheets(userId: userId) { result in
            switch result {
            case .success(let testsheets):
                documents.append(contentsOf: testsheets)
            case .failure(let err):
                error = err
            }
            group.leave()
        }
        
        group.enter()
        getWrongsheets(userId: userId) { result in
            switch result {
            case .success(let wrongsheets):
                documents.append(contentsOf: wrongsheets)
            case .failure(let err):
                error = err
            }
            group.leave()
        }
        
        group.notify(queue: .main) {
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(documents))
            }
        }
    }
    
    // MARK: - Mock Data
    
    func getMockTestsheets() -> [Testsheet] {
        return [
            Testsheet(testsheetId: 1, name: "Testsheet 1", category: "Math", testsheetBookmark: true, testsheetCreateDate: Date()),
            Testsheet(testsheetId: 2, name: "Testsheet 2", category: "Science", testsheetBookmark: false, testsheetCreateDate: Date()),
            Testsheet(testsheetId: 3, name: "Testsheet 3", category: "History", testsheetBookmark: true, testsheetCreateDate: Date())
        ]
    }
    
    func getMockTestsheetDetail() -> TestsheetDetail {
        return TestsheetDetail(testsheetId: 1, name: "Testsheet 1", category: "Math", isReExtracted: false, questions1: [
            Question(questionId: 1, question: "Question 1", answer: "Answer 1", userAnswer: nil),
            Question(questionId: 2, question: "Question 2", answer: "Answer 2", userAnswer: nil),
            Question(questionId: 3, question: "Question 3", answer: "Answer 1", userAnswer: nil),
            Question(questionId: 4, question: "Question 4", answer: "Answer 2", userAnswer: nil),
            Question(questionId: 5, question: "Question 5", answer: "Answer 1", userAnswer: nil),
            Question(questionId: 6, question: "Question 6", answer: "Answer 2", userAnswer: nil)
        ], questions2: [
            Question(questionId: 7, question: "Question 7", answer: "Answer 3", userAnswer: nil),
            Question(questionId: 8, question: "Question 8", answer: "Answer 4", userAnswer: nil),
            Question(questionId: 9, question: "Question 9", answer: "Answer 1", userAnswer: nil),
            Question(questionId: 10, question: "Question 10", answer: "Answer 2", userAnswer: nil)
        ])
    }
    
    func getMockWrongsheets() -> [Wrongsheet] {
        return [
            Wrongsheet(wrongsheetId: 1, name: "Wrongsheet 1", category: "Math", wrongsheetBookmark: true, wrongsheetCreate_date: Date()),
            Wrongsheet(wrongsheetId: 2, name: "Wrongsheet 2", category: "Science", wrongsheetBookmark: false, wrongsheetCreate_date: Date()),
            Wrongsheet(wrongsheetId: 3, name: "Wrongsheet 3", category: "History", wrongsheetBookmark: true, wrongsheetCreate_date: Date())
        ]
    }
    
    func getMockWrongsheetDetail() -> WrongsheetDetail {
        return WrongsheetDetail(wrongsheetId: 1, name: "Wrongsheet 1", category: "Math", questions: [
            Question(questionId: 1, question: "Question 1", answer: "Answer 1", userAnswer: nil),
            Question(questionId: 2, question: "Question 2", answer: "Answer 2", userAnswer: nil)
        ])
    }
}
