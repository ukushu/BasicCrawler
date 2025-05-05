
import Foundation

public class GSheets {
    let apiKey: String
    
    public init(apiKey: String) {
        self.apiKey = apiKey
    }
    
    public func fetch(sheetID: String, page: String, range: String ) async throws -> [[String]] {
        let tmp = await withCheckedContinuation { continuation in
            fetch(sheetID: sheetID, page: page, range: range) { rez in
                continuation.resume(returning: rez)
            }
        }
        
        switch tmp {
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
    
    public func put(sheetID: String, page: String, range: String, values: [[String]]) async throws {
        let tmp = await withCheckedContinuation { continuation in
            put(sheetID: sheetID, page: page, range: range, values: values) { rez in
                continuation.resume(returning: rez)
            }
        }
        
        switch tmp {
        case .failure(let e):
            throw e
        case .success():
            return
        }
    }
    
    public func put(sheetID: String,
                    page: String,
                    range: String,
                    values: [[String]],
                    completion: @escaping (Result<Void, Error>) -> Void)
    {
        let urlString = "https://sheets.googleapis.com/v4/spreadsheets/\(sheetID)/values/\(page)!\(range)?valueInputOption=RAW&key=\(apiKey)"
        
        guard let url = URL(string: urlString) else {
            completion(.failure(NSError(domain: "Invalid URL", code: 0)))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "range": range,
            "majorDimension": "ROWS",
            "values": values
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])
        } catch {
            completion(.failure(error))
            return
        }
        
        let task = URLSession.shared.dataTask(with: request) { _, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
                let tmp = httpResponse.statusCode == 401 ? " Possible issue reason: API keys are only valid for accessing public data... Modifying spreadsheet data requires authenticated requests using OAuth 2.0." : ""
                
                let error = NSError(domain: "Google Sheets API\(tmp)", code: httpResponse.statusCode, userInfo: nil)
                completion(.failure(error))
                return
            }
            
            completion(.success(()))
        }
        
        task.resume()
    }
}

fileprivate struct SheetResponse: Codable {
    let range: String
    let majorDimension: String
    let values: [[String]]
}
