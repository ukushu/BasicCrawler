
import Foundation
import Essentials

public func getHtmlSync(from urlStr: String, cookies: [HTTPCookie]) -> String? {
    getJsonFuture(from: urlStr, cookies: cookies).wait().maybeSuccess
}

public func getHtmlFuture(from urlStr: String, cookies: [HTTPCookie]) -> Flow.Future<String> {
    getJsonFuture(from: urlStr, cookies: cookies)
}

public func getHtmlAsync(from urlStr: String) async -> String? {
    return await getJsonAsync(from: urlStr)
}
