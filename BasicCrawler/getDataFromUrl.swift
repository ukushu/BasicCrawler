
import Foundation
import Essentials

public func getDataAsync(from urlStr: String, cookies: [HTTPCookie]) async throws -> Data? {
    guard let url = URL(string: urlStr) else { throw WTF("incorrect url") }
    
    return try await withUnsafeThrowingContinuation { continuation in
        URLSession.shared.dataTask(with: url) { data, _, _ in
            continuation.resume(returning: data)
        }.resume()
    }
}

public func getDataFuture(from urlStr: String, cookies: [HTTPCookie]) -> Flow.Future<Data> {
    guard let url = URL(string: urlStr) else {
        return .failed(WTF("Wrong URL"))
    }
    
    return Flow.Future {
        let config = URLSessionConfiguration.default
        config.headers = [ "User-Agent": userAgentsList.randomElement()! ]
        
        let session = URLSession(configuration: config, delegate: nil, delegateQueue: nil)
        
        let cookieStorage = HTTPCookieStorage()
        
        for c in cookies {
            cookieStorage.setCookie(c)
        }
        
        let (data, _) = try await session.data(from: url)
        
        return data
    }
}
