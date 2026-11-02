// Shared example infrastructure; not part of the PCPClient SDK product.
import Foundation

/// JSON transport only. Checkout state and validation remain in ApplePayDemoCheckout.
struct DemoBackendClient {
    let baseURL: URL
    let session: URLSession

    func post<Response: Decodable>(
        _ path: String, body: [String: Any], as: Response.Type,
        completion: @escaping (Result<Response, Error>) -> Void
    ) {
        do {
            var request = URLRequest(url: baseURL.appendingPathComponent(path))
            request.httpMethod = "POST"
            request.timeoutInterval = 20
            request.cachePolicy = .reloadIgnoringLocalCacheData
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
            session.dataTask(with: request) { data, response, error in
                let result: Result<Response, Error>
                if let error {
                    result = .failure(error)
                } else if (response as? HTTPURLResponse)?.statusCode == 200, let data {
                    result = Result { try JSONDecoder().decode(Response.self, from: data) }
                } else {
                    result = .failure(DemoCheckoutError.http((response as? HTTPURLResponse)?.statusCode ?? 0))
                }
                DispatchQueue.main.async { completion(result) }
            }.resume()
        } catch {
            completion(.failure(error))
        }
    }
}
