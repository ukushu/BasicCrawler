import Foundation

@available(macOS 10.15, *)
private final class RunBlocking<T, Failure: Error> {
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
            while value == nil {
                RunLoop.current.run(mode: .default, before: .distantFuture)
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

let queues: [DispatchQueue] = [
    DispatchQueue.global(),
    DispatchQueue.global(qos: .userInteractive),
    DispatchQueue.global(qos: .userInitiated),
    DispatchQueue.global(qos: .background),
    DispatchQueue.global(qos: .utility)
]

@available(macOS 10.15, *)
extension RunBlocking where Failure == Error {
    func runBlocking(_ operation: @Sendable @escaping () async throws -> T) throws -> T {
        Task {
            let task = Task(operation: operation)
            value = await task.result
        }
        
        queues.shuffled().first!.sync {
            while value == nil {
                RunLoop.current.run(mode: .default, before: .distantFuture)
            }
        }
        
        switch value {
        case let .success(value):
            return value
        case let .failure(error):
            throw error
        case .none:
            fatalError("Run blocking not received value")
        }
    }
}

/// ```
/// //Sample of usage
/// let html = getSyncResultFrom {
///    let loader = await MyInternetLoader()
///
///    return try? await loader.getHTML(from: URL(string: url)!)
/// }
@available(macOS 10.15, *)
public func getSyncResultFrom<T>(@_implicitSelfCapture _ operation: @Sendable @escaping () async -> T) -> T {
    RunBlocking().runBlocking(operation)
}

/// ```
/// //Sample of usage
/// let html = getSyncResultFrom {
///    let loader = await MyInternetLoader()
///
///    return try? await loader.getHTML(from: URL(string: url)!)
/// }
@available(macOS 10.15, *)
public func getSyncResultFrom<T>(@_implicitSelfCapture _ operation: @Sendable @escaping () async throws -> T) throws -> T {
    try RunBlocking().runBlocking(operation)
}
