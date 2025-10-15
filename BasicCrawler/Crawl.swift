
import Foundation
import Essentials
import AppKit

public struct Crawl {
    public struct Html {
        /// You can use [ access: .advanced ] in case of you some html loaded with ajax and you don't have access to those html in [ access: .fast] mode
        public static func getSync(from urlStr: String, cookies: [HTTPCookie], access: UrlAccessType = .fast) -> String? {
            if access == .fast {
                return getHtmlFuture(from: urlStr, cookies: cookies).wait().maybeSuccess
            } else {
                // need to use AsyncToSync to make sure correct work of UrlAccessType.advanced
                return try? AsyncToSync.getFrom {
                    try await Crawl.Html.getAsync(from: urlStr, cookies: cookies, access: access)
                }
            }
        }
        
        /// You can use [ access: .advanced ] in case of you some html loaded with ajax and you don't have access to those html in [ access: .fast] mode
        public static func getAsyncF(from urlStr: String, cookies: [HTTPCookie], access: UrlAccessType = .fast) -> Flow.Future<String>
        {
            if access == .fast {
                return getHtmlFuture(from: urlStr, cookies: cookies)
            } else {
                return Flow.Future { try await Crawl.Html.getAsync(from: urlStr, cookies: cookies, access: access) }
            }
        }
        
        /// You can use [ access: .advanced ] in case of you some html loaded with ajax and you don't have access to those html in [ access: .fast] mode
        public static func getAsync(from urlStr: String, cookies: [HTTPCookie], access: UrlAccessType = .fast) async throws -> String
        {
            if access == .fast {
                return try await getHtmlAsync(from: urlStr, cookies: cookies)
            } else {
                let loader = await MyInternetLoader()
                
                guard let html = try await loader.getHTML(from: URL(string: urlStr)!, cookies: cookies)
                else { throw WTF("No Html found") }
                
                return html.removingPercentEncoding ?? html
            }
        }
    }
    
    public struct Data {
        public static func getSync(from urlStr: String, cookies: [HTTPCookie]) -> Foundation.Data? {
            Crawl.Data.getAsyncF(from: urlStr, cookies: cookies).wait().maybeSuccess
        }
        
        public static func getAsyncF(from urlStr: String, cookies: [HTTPCookie]) -> Flow.Future<Foundation.Data> {
            getDataFuture(from: urlStr, cookies: cookies)
        }
        
        public static func getAsync(from urlStr: String, cookies: [HTTPCookie]) async throws -> Foundation.Data? {
            try await getDataAsync(from: urlStr, cookies: cookies)
        }
    }
    
    public struct Json {
        public static func getSync(from urlStr: String, cookies: [HTTPCookie]) -> String? {
            getAsyncF(from: urlStr, cookies: cookies).wait().maybeSuccess
        }
        
        public static func getAsyncF(from urlStr: String, cookies: [HTTPCookie]) -> Flow.Future<String> {
            Flow.Future { try await getJsonAsync(from: urlStr, cookies: cookies) }
        }
        
        public static func getAsync(from urlStr: String, cookies: [HTTPCookie]) async throws -> String {
            try await getJsonAsync(from: urlStr, cookies: cookies)
        }
    }
    
    public struct File {
        public static func imgSync(from urlStr: String, cookies: [HTTPCookie]) async -> NSImage? {
            imgAsyncF(from: urlStr, cookies: cookies).wait().maybeSuccess
        }
        
        public static func imgAsyncF(from urlStr: String, cookies: [HTTPCookie]) -> Flow.Future<NSImage> {
            Flow.Future { try await imgAsync(from: urlStr, cookies: cookies) }
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
