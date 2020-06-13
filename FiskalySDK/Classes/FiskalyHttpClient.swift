import Foundation

public class FiskalyHttpClient {

    private var context: String
    private let client: RequestClient

    /*
     Initializer
     */

    public init(apiKey: String, apiSecret: String, baseUrl: String, client: RequestClient = FiskalyRequestClient()) throws {
        self.client = client

        // this needs to be done because xcode cries that self.context is used before be initialized

        self.context = ""

        // version is hardcorded because using versionNumber from header file strips patch number

        let contextRequestParams: [String: String] = [
            "api_key": apiKey,
            "api_secret": apiSecret,
            "base_url": baseUrl,
            "sdk_version": "iOS SDK 1.1.600"
        ]

        let request = JsonRpcRequest(method: "create-context", params: contextRequestParams)
        let response = try performJsonRpcRequest(request: request, ResultCreateContext.self)
        if let result = response.result {
            self.context = result.context
        } else if let error = response.error {
            throw error
        } else {
            throw FiskalyError.sdkError(message: "Client error not readable.")
        }

    }

    /*
     Method: Version
     */

    public func version() throws -> ResultVersion {

        let request = JsonRpcRequest(method: "version", params: "")
        let response = try performJsonRpcRequest(request: request, ResultVersion.self)
        if let result = response.result {
            return result
        } else if let error = response.error {
            throw error
        } else {
            throw FiskalyError.sdkError(message: "Client error not readable.")
        }

    }

    /*
     Method: Config
     */

    public func config(debugLevel: Int?, debugFile: String?, clientTimeout: Int?, smaersTimeout: Int?) throws -> Config {

        let configRequestParams: [String: Any] = [
            "context": self.context,
            "config": [
                "debug_level": debugLevel ?? -1,
                "debug_file": debugFile ?? "",
                "client_timeout": clientTimeout ?? 0,
                "smaers_timeout": smaersTimeout ?? 0
            ]
        ]

        let request = JsonRpcRequest(method: "config", params: configRequestParams)
        let response = try performJsonRpcRequest(request: request, ResultConfig.self)
        if let result = response.result {
            self.context = result.context
            return result.config
        } else if let error = response.error {
            throw error
        } else {
            throw FiskalyError.sdkError(message: "Client error not readable.")
        }

    }

    /*
     Method: Echo
     */

    public func echo(data: String) throws -> String {

        let request = JsonRpcRequest(method: "echo", params: data)
        let response = try performJsonRpcRequest(request: request, String.self)
        if let result = response.result {
            return result
        } else if let error = response.error {
            throw error
        } else {
            throw FiskalyError.sdkError(message: "Client error not readable.")
        }

    }

    /*
     Method: Request
     */

    public func request( method: String,
                         path: String = "",
                         query: [String: String]? = nil,
                         headers: [String: String]? = nil,
                         body: String = "") throws -> HttpResponse {

        let requestRequestParams: [String: Any] = [
            "context": self.context,
            "request": [
                "method": method,
                "path": path,
                "body": body as Any,
                "query": query as Any,
                "headers": headers as Any
            ]
        ]

        let request = JsonRpcRequest(method: "request", params: requestRequestParams)
        let response = try performJsonRpcRequest(request: request, ResultRequest.self)
        if let result = response.result {
            if let context = result.context {
                self.context = context
                return result.response
            } else {
                throw FiskalyError.sdkError(message: "Client did not respond with a proper response.")
            }
        } else if let error = response.error {
            throw error
        } else {
            throw FiskalyError.sdkError(message: "Client error not readable.")
        }

    }

    func performJsonRpcRequest<T: Codable>(request: JsonRpcRequest, _ type: T.Type) throws -> JsonRpcResponse<T> {

        let jsonData = try client.invoke(request: request)
        guard let data = jsonData.data(using: .utf8) else {
            throw FiskalyError.sdkError(message: "Client response not decodeable into JSON.")
        }

        let response: JsonRpcResponse<T>

        do {
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            response = try decoder.decode(JsonRpcResponse<T>.self, from: data)
        } catch {
            throw FiskalyError.sdkError(message: "Client response not decodable into class.")
        }

        return response

    }

}