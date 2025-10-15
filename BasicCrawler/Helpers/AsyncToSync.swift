
import Foundation
import AppKit
import Essentials

struct AsyncToSync {
    /// ```
    /// //Sample of usage (no try/throws)
    ///
    /// let html = getSyncResultFrom {
    ///    let loader = await MyInternetLoader()
    ///
    ///    return try? await loader.getHTML(from: URL(string: url)!)
    /// }
    /// ```
    @available(macOS 10.15, *)
    static func getFrom<T>(@_implicitSelfCapture _ operation: @Sendable @escaping () async -> T) -> T {
        RunBlocking().runBlocking(operation)
    }
    
    /// ```
    /// //Sample of usage (try/throws)
    ///
    /// let html = getSyncResultFrom {
    ///    let loader = await MyInternetLoader()
    ///
    ///    return try? await loader.getHTML(from: URL(string: url)!)
    /// }
    /// ```
    @available(macOS 10.15, *)
    static func getFrom<T>(@_implicitSelfCapture _ operation: @Sendable @escaping () async throws -> T) throws -> T {
        try RunBlocking().runBlocking(operation)
    }
}





//
// Helpers
//

@available(macOS 10.15, *)
fileprivate final class RunBlocking<T, Failure: Error> {
    fileprivate var value: Result<T, Failure>? = nil
}

@available(macOS 10.15, *)
extension RunBlocking where Failure == Never {
    func runBlocking(_ operation: @Sendable @escaping () async -> T) -> T {
        Task {
            let task = Task(operation: operation)
            self.value = await task.result
        }
        
        DispatchQueue.global().sync {
//        queues.shuffled().first!.sync {
            while value == nil {
                RunLoop.current.run(mode: .default, before: .now.adding(.second, value: 60))
            }
        }
        
        switch value {
        case let .success(value):
            return value
        case .none:
            fatalError("Run blocking not received value")
        }
    }
}

@available(macOS 10.15, *)
extension RunBlocking where Failure == Error {
    func runBlocking(_ operation: @Sendable @escaping () async throws -> T) throws -> T {
        Task {
            let task = Task(operation: operation)
            value = await task.result
        }
        
        DispatchQueue.global().sync {
//        queues.shuffled().first!.sync {
            while value == nil {
                RunLoop.current.run(mode: .default, before: .now.adding(.second, value: 60))
            }
        }
        
        switch value {
        case let .success(value):
            return value
        case let .failure(error):
            throw error
        case .none:
            throw WTF("Run blocking not received value")
        }
    }
}

//
// Helpers
//

//let queues: [DispatchQueue] = [
//    .global(),
//    .global(qos: .userInteractive),
//    .global(qos: .userInitiated),
//    .global(qos: .background),
//    .global(qos: .utility)
//]
