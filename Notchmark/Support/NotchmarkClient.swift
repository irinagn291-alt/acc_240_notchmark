import Foundation

/// Role: Support. Typed transport failures. This product has no remote catalog.
enum NotchmarkClientError: Error, Equatable, Sendable {
    case notFound
    case decoding
    case transport
    case cancelled
    case invalidResponse
}

/// Role: Support. Sends one HTTP request. Injected so tests never hit the network.
protocol HTTPTransport: Sendable {
    func data(for request: URLRequest) async throws -> (Data, URLResponse)
}

/// Role: Support. URLSession-backed transport with a 15 s timeout and the app User-Agent.
struct URLSessionTransport: HTTPTransport {
    let session: URLSession

    init(session: URLSession) {
        self.session = session
    }

    init() {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.timeoutIntervalForRequest = 15
        configuration.timeoutIntervalForResource = 15
        configuration.httpAdditionalHeaders = ["User-Agent": NotchmarkClient.userAgent]
        self.session = URLSession(configuration: configuration)
    }

    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        try await session.data(for: request)
    }
}

/// Role: Support. Accepts a JSON number or a numeric string. Missing values stay nil.
struct FlexibleDouble: Sendable, Equatable {
    var value: Double?
}

extension FlexibleDouble: Decodable {
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if container.decodeNil() {
            value = nil
            return
        }
        if let number = try? container.decode(Double.self) {
            value = number
            return
        }
        if let number = try? container.decode(Int.self) {
            value = Double(number)
            return
        }
        if let text = try? container.decode(String.self) {
            value = Double(text)
            return
        }
        value = nil
    }
}

/// Role: Support. Owns URLSession. Offline rail; this is the transport seam only.
actor NotchmarkClient {
    static let userAgent = "Notchmark/1.0 (iOS; +https://travelhel-per.pro)"

    private let transport: any HTTPTransport

    init(transport: any HTTPTransport) {
        self.transport = transport
    }

    init() {
        self.transport = URLSessionTransport()
    }

    func getJSON<DTO: Decodable>(_ type: DTO.Type, from url: URL) async throws -> DTO {
        try Task.checkCancellation()
        let data = try await fetch(makeRequest(url: url))
        do {
            return try JSONDecoder().decode(DTO.self, from: data)
        } catch is CancellationError {
            throw NotchmarkClientError.cancelled
        } catch {
            throw NotchmarkClientError.decoding
        }
    }

    private func makeRequest(url: URL) -> URLRequest {
        var request = URLRequest(url: url, timeoutInterval: 15)
        request.setValue(Self.userAgent, forHTTPHeaderField: "User-Agent")
        return request
    }

    private func fetch(_ request: URLRequest) async throws -> Data {
        do {
            return try await send(request)
        } catch let error as NotchmarkClientError {
            throw error
        } catch is CancellationError {
            throw NotchmarkClientError.cancelled
        } catch {
            if isCancelled(error) {
                throw NotchmarkClientError.cancelled
            }
            guard isTransient(error) else { throw NotchmarkClientError.transport }
            do {
                return try await send(request)
            } catch let error as NotchmarkClientError {
                throw error
            } catch is CancellationError {
                throw NotchmarkClientError.cancelled
            } catch {
                if isCancelled(error) { throw NotchmarkClientError.cancelled }
                throw NotchmarkClientError.transport
            }
        }
    }

    private func send(_ request: URLRequest) async throws -> Data {
        try Task.checkCancellation()
        let (data, response) = try await transport.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw NotchmarkClientError.invalidResponse
        }
        if http.statusCode == 404 {
            throw NotchmarkClientError.notFound
        }
        guard (200 ..< 300).contains(http.statusCode) else {
            throw NotchmarkClientError.transport
        }
        return data
    }
}

func isTransient(_ error: Error) -> Bool {
    guard let urlError = error as? URLError else { return false }
    switch urlError.code {
    case .timedOut, .networkConnectionLost, .notConnectedToInternet,
         .cannotConnectToHost, .cannotFindHost, .dnsLookupFailed:
        return true
    default:
        return false
    }
}

func isCancelled(_ error: Error) -> Bool {
    if error is CancellationError { return true }
    return (error as? URLError)?.code == .cancelled
}
