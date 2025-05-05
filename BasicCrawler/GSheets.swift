
import Foundation

public class GSheets {
    let apiKey: String
    
    public init(apiKey: String) {
        self.apiKey = apiKey
    }
    
    public func fetch(sheetID: String,
                      page: String,
                      range: String
    ) async throws -> [[String]]
    {
        let a = await withCheckedContinuation { continuation in
            fetch(sheetID: sheetID, page: page, range: range) { rez in
                continuation.resume(returning: rez)
            }
        }
        
        switch a {
        case .failure(let e):
            throw e
        case .success(let s):
            return s
        }
    }
    
    public func fetch(sheetID: String,
                      page: String,
                      range: String,
                      completion: @escaping (Result<[[String]], Error>) -> Void)
    {
        let urlString = "https://sheets.googleapis.com/v4/spreadsheets/\(sheetID)/values/\(page)!\(range)?key=\(apiKey)"
        
        guard let url = URL(string: urlString) else {
            completion(.failure(NSError(domain: "Invalid URL", code: 0)))
            return
        }
        
        let task = URLSession.shared.dataTask(with: url) { data, _, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(NSError(domain: "No data", code: 0)))
                return
            }
            
            do {
                let decoded = try JSONDecoder().decode(SheetResponse.self, from: data)
                completion(.success(decoded.values))
            } catch {
                completion(.failure(error))
            }
        }
        
        task.resume()
    }
}

fileprivate struct SheetResponse: Codable {
    let range: String
    let majorDimension: String
    let values: [[String]]
}
