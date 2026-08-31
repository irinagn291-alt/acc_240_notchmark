import XCTest
@testable import Notchmark

private struct ProbeDTO: Decodable {
    var price: FlexibleDouble
}

private actor ScriptedTransport: HTTPTransport {
    private var results: [Result<(Data, URLResponse), Error>]
    private var requests: [URLRequest] = []

    init(results: [Result<(Data, URLResponse), Error>]) {
        self.results = results
    }

    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        requests.append(request)
        guard !results.isEmpty else { throw URLError(.cannotConnectToHost) }
        return try results.removeFirst().get()
    }

    func recordedRequests() -> [URLRequest] {
        requests
    }
}

final class NotchmarkClientTests: XCTestCase {
    private let url = URL(string: "https://travelhel-per.pro/probe")!

    func test_setsUserAgentOnEveryRequest() async throws {
        let transport = ScriptedTransport(results: [
            .success((Data("{\"price\":1}".utf8), http(200))),
        ])
        let client = NotchmarkClient(transport: transport)
        _ = try await client.getJSON(ProbeDTO.self, from: url)
        let request = await transport.recordedRequests().first
        XCTAssertEqual(request?.value(forHTTPHeaderField: "User-Agent"), NotchmarkClient.userAgent)
        XCTAssertEqual(request?.timeoutInterval, 15)
    }

    func test_retriesTransientTransportOnce() async throws {
        let transport = ScriptedTransport(results: [
            .failure(URLError(.timedOut)),
            .success((Data("{\"price\":\"4.5\"}".utf8), http(200))),
        ])
        let client = NotchmarkClient(transport: transport)
        let dto = try await client.getJSON(ProbeDTO.self, from: url)
        XCTAssertEqual(dto.price.value, 4.5)
        let count = await transport.recordedRequests().count
        XCTAssertEqual(count, 2)
    }

    func test_doesNotRetry404() async {
        let transport = ScriptedTransport(results: [
            .success((Data(), http(404))),
            .success((Data("{\"price\":1}".utf8), http(200))),
        ])
        let client = NotchmarkClient(transport: transport)
        do {
            _ = try await client.getJSON(ProbeDTO.self, from: url)
            XCTFail("expected notFound")
        } catch {
            XCTAssertEqual(error as? NotchmarkClientError, .notFound)
        }
        let count = await transport.recordedRequests().count
        XCTAssertEqual(count, 1)
    }

    func test_malformedJSONIsDecodingError() async {
        let transport = ScriptedTransport(results: [
            .success((Data("{".utf8), http(200))),
        ])
        let client = NotchmarkClient(transport: transport)
        do {
            _ = try await client.getJSON(ProbeDTO.self, from: url)
            XCTFail("expected decoding")
        } catch {
            XCTAssertEqual(error as? NotchmarkClientError, .decoding)
        }
    }

    func test_flexibleDoubleAcceptsNumberAndString() throws {
        let number = try JSONDecoder().decode(ProbeDTO.self, from: Data("{\"price\":12.5}".utf8))
        let string = try JSONDecoder().decode(ProbeDTO.self, from: Data("{\"price\":\"12.5\"}".utf8))
        let missing = try JSONDecoder().decode(ProbeDTO.self, from: Data("{\"price\":null}".utf8))
        XCTAssertEqual(number.price.value, 12.5)
        XCTAssertEqual(string.price.value, 12.5)
        XCTAssertNil(missing.price.value)
    }

    private func http(_ status: Int) -> HTTPURLResponse {
        HTTPURLResponse(url: url, statusCode: status, httpVersion: nil, headerFields: nil)!
    }
}
