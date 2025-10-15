
import Foundation
import Essentials

public func getDataAsync(from urlStr: String, cookies: [HTTPCookie]) async throws -> Data? {
    guard let url = URL(string: urlStr) else { throw WTF("incorrect url") }
    
    let session = createSession(cookies: cookies)
    
    return try await withUnsafeThrowingContinuation { continuation in
        session.dataTask(with: url) { data, _, _ in
            continuation.resume(returning: data)
        }.resume()
    }
}

public func getDataFuture(from urlStr: String, cookies: [HTTPCookie]) -> Flow.Future<Data> {
    guard let url = URL(string: urlStr) else {
        return .failed(WTF("Wrong URL"))
    }
    
    return Flow.Future {
        let session = createSession(cookies: cookies)
        
        let (data, _) = try await session.data(from: url)
        
        return data
    }
}
