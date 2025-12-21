import Foundation

internal class NetworkManager {
    static let shared = NetworkManager()

    #if DEBUG
    static let isDebug = true
    #else
    static let isDebug = false
    #endif

    private let baseURL = "https://wlbsugnskuojugsubnjj.supabase.co/functions/v1"
    private let timeout: TimeInterval = 30

    private init() {}

    func register(
        apiKey: String,
        userId: String,
        apnToken: String,
        sdk: String,
        completion: @escaping (Result<String, Error>) -> Void
    ) {
        let body: [String: Any] = [
            "user_id": userId,
            "apn_token": apnToken,
            "is_sandbox": NetworkManager.isDebug,
            "sdk": sdk,
            "is_debug": NetworkManager.isDebug,
        ]

        let headers = [
            "Authorization": "Bearer \(apiKey)",
            "Content-Type": "application/json"
        ]

        sendRequest(
            endpoint: "/register",
            method: "POST",
            body: body,
            headers: headers
        ) { result in
            switch result {
            case .success(let data):
                do {
                    if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let registrationId = json["id"] as? String {
                        completion(.success(registrationId))
                    } else {
                        completion(.failure(NSError(
                            domain: "EntrigSDK",
                            code: -1,
                            userInfo: [NSLocalizedDescriptionKey: "Invalid response format"]
                        )))
                    }
                } catch {
                    completion(.failure(error))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    func unregister(
        apiKey: String,
        registrationId: String,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        let body: [String: Any] = [
            "id": registrationId
        ]

        let headers = [
            "Authorization": "Bearer \(apiKey)",
            "Content-Type": "application/json"
        ]

        sendRequest(
            endpoint: "/unregister",
            method: "POST",
            body: body,
            headers: headers
        ) { result in
            switch result {
            case .success:
                completion(.success(()))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    private func sendRequest(
        endpoint: String,
        method: String,
        body: [String: Any],
        headers: [String: String],
        completion: @escaping (Result<Data, Error>) -> Void
    ) {
        guard let url = URL(string: baseURL + endpoint) else {
            completion(.failure(NSError(
                domain: "EntrigSDK",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Invalid URL"]
            )))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = method
        request.timeoutInterval = timeout

        headers.forEach { key, value in
            request.setValue(value, forHTTPHeaderField: key)
        }

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        } catch {
            completion(.failure(error))
            return
        }

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let data = data else {
                completion(.failure(NSError(
                    domain: "EntrigSDK",
                    code: -1,
                    userInfo: [NSLocalizedDescriptionKey: "No data received"]
                )))
                return
            }

            completion(.success(data))
        }

        task.resume()
    }
}
