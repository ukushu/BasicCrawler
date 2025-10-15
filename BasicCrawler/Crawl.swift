
import Foundation
import Essentials
import AppKit

struct Crawl {
    struct Html {
        public static func getSync(from urlStr: String, cookies: [HTTPCookie]) -> String? {
            getHtmlFuture(from: urlStr, cookies: cookies).wait().maybeSuccess
        }
        
        public static func getAsyncF(from urlStr: String, cookies: [HTTPCookie]) -> Flow.Future<String> {
            getHtmlFuture(from: urlStr, cookies: cookies)
        }
        
        public static func getAsync(from urlStr: String) async throws -> String {
            try await getJsonAsync(from: urlStr)
        }
        
        public static func getAdvancedSync(url: String, cookies: [HTTPCookie]) throws -> String? {
            try AsyncToSync.getFrom {
                try await Crawl.Html.getAdvancedAsync(from: url, cookies: cookies)
            }
        }
        
        public static func getAdvancedAsync(from urlStr: String, cookies: [HTTPCookie]) async throws -> String? {
            let loader = await MyInternetLoader()
            
            guard let html = try await loader.getHTML(from: URL(string: urlStr)!, cookies: cookies)
            else { return nil }
            
            return html.removingPercentEncoding ?? html
        }
    }
    
    struct Data {
        public static func getSync(from urlStr: String, cookies: [HTTPCookie]) -> Foundation.Data? {
            Crawl.Data.getAsyncF(from: urlStr, cookies: cookies).wait().maybeSuccess
        }
        
        public static func getAsync(from urlStr: String, cookies: [HTTPCookie]) async throws -> Foundation.Data? {
            try await getDataAsync(from: urlStr, cookies: cookies)
        }
        
        public static func getAsyncF(from urlStr: String, cookies: [HTTPCookie]) -> Flow.Future<Foundation.Data> {
            getDataFuture(from: urlStr, cookies: cookies)
        }
    }
    
    struct Json {
        public static func getSync(from urlStr: String, cookies: [HTTPCookie]) -> String? {
            getJsonFuture(from: urlStr, cookies: cookies).wait().maybeSuccess
        }
        
        public static func getAsync(from urlStr: String) async throws -> String {
            try await getJsonAsync(from: urlStr)
        }
        
        public static func getAsyncF(from urlStr: String, cookies: [HTTPCookie]) -> Flow.Future<String> {
            getJsonFuture(from: urlStr, cookies: cookies)
        }
    }
    
    struct File {
        public static func imgSync(from urlStr: String, cookies: [HTTPCookie]) async -> NSImage? {
            if let data = Crawl.Data.getAsyncF(from: urlStr, cookies: cookies).wait().maybeSuccess {
                return NSImage(data: data)
            }
            
            return nil
        }
        
        public static func imgAsync(from urlStr: String, cookies: [HTTPCookie]) async throws -> NSImage {
            guard let data = try await Crawl.Data.getAsync(from: urlStr, cookies: cookies),
                  let nsImg = NSImage(data: data)
            else {
                throw WTF("no image data there")
            }
            
            return nsImg
        }
    }
}
