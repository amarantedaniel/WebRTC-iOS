
import Foundation

enum JanusWebGateError: Error {
    case runtimeError(String)
}

class Utilites {
    static func randomString(length: Int) -> String {
        let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        return String((0...length - 1).map { _ in letters.randomElement()! })
    }
}

class JanusRequestsBuilder {
    private let baseUrl: String
    
    init(url: String) {
        var tempUrl = url
        while tempUrl.last == "/" {
            tempUrl.removeLast()
        }
        
        self.baseUrl = tempUrl
    }
    
    func createJanusSessionRequestWith(transactionId: String) -> URLRequest {
        let body = "{\"janus\":\"create\",\"transaction\":\"\(transactionId)\"}"
        
        return self.POSTRequestWith(body: body)
    }
    
    func createGetStreamsListRequestWith(sessionId: Int64, streamPluginId: Int64, transactionId: String) -> URLRequest {
        let body = "{\"request\" : \"list\"}"
        let rBody = "{\"janus\":\"message\", \"transaction\":\"\(transactionId)\", \"body\" : \(body) }"
        
        return self.POSTRequestWith(body: rBody, sessionId: sessionId, pluginId: streamPluginId)
    }
    
    func createWatchOfferRequestWith(sessionId: Int64, streamPluginId: Int64, transactionId: String, streamId: Int) -> URLRequest {
        let body = "{\"request\" : \"watch\", \"id\" : \(streamId)}"
        let rBody = "{\"janus\":\"message\", \"transaction\":\"\(transactionId)\", \"body\" : \(body) }"
        
        return self.POSTRequestWith(body: rBody, sessionId: sessionId, pluginId: streamPluginId)
    }
    
    func createRestartActiveStreamRequestWith(sessionId: Int64, streamPluginId: Int64, transactionId: String) -> URLRequest {
        let body = "{\"request\" : \"start\"}"
        let rBody = "{\"janus\":\"message\", \"transaction\":\"\(transactionId)\", \"body\" : \(body) }"
        
        return self.POSTRequestWith(body: rBody, sessionId: sessionId, pluginId: streamPluginId)
    }
    
    func createLocalCandidateCompleteRequestWith(sessionId: Int64, streamPluginId: Int64, transactionId: String) -> URLRequest {
        let body = "{\"janus\":\"trickle\",\"candidate\":{\"completed\":true},\"transaction\":\"\(transactionId)\"}"
        
        return self.POSTRequestWith(body: body, sessionId: sessionId, pluginId: streamPluginId)
    }
    
    func createPauseActiveStreamRequestWith(sessionId: Int64, streamPluginId: Int64, transactionId: String) -> URLRequest {
        let body = "{\"request\" : \"pause\"}"
        let rBody = "{\"janus\":\"message\", \"transaction\":\"\(transactionId)\", \"body\" : \(body) }"
        
        return self.POSTRequestWith(body: rBody, sessionId: sessionId, pluginId: streamPluginId)
    }
    
    func createStopActiveStreamRequestWith(sessionId: Int64, streamPluginId: Int64, transactionId: String) -> URLRequest {
        let body = "{\"request\" : \"stop\"}"
        let rBody = "{\"janus\":\"message\", \"transaction\":\"\(transactionId)\", \"body\" : \(body) }"
        
        return self.POSTRequestWith(body: rBody, sessionId: sessionId, pluginId: streamPluginId)
    }
    
    func createStartCommandRequestWith(sessionId: Int64, streamPluginId: Int64, transactionId: String, sdp: String) -> URLRequest {
        let jsep = JanusJSEPOUTPUTData(type: "answer", sdp: sdp)
        let body = JanusStartRequestBody(request: "start")
        let mess = JanusOUTPUTMessageWithStartRequest(janus: "message", transaction: "\(transactionId)", body: body, jsep: jsep)
        
        let data = try? JSONEncoder().encode(mess)
        
        print("!!!!!START REQUEST : \(String(data: data!, encoding: .utf8) ?? "!!!")")
        
        return self.POSTRequestWith(body: data!, sessionId: sessionId, pluginId: streamPluginId)
    }
    
    func createTrickleCandidateRequestWith(sessionId: Int64, streamPluginId: Int64, transactionId: String, candidate: String, sdpMLineIndex: Int32, sdpMid: String) -> URLRequest {
        let candidate = JanusTrickleCandidate(sdpMid: sdpMid, sdpMLineIndex: sdpMLineIndex, candidate: candidate)
        let body = JanusTrickleLocalCandidate(
            janus: "trickle",
            transaction: transactionId,
            candidate: candidate
        )
        
        let data = try? JSONEncoder().encode(body)
        
        print("TRICKLE REQUEST : \(String(data: data!, encoding: .utf8) ?? "!!!")")
        
        return self.POSTRequestWith(body: data!, sessionId: sessionId, pluginId: streamPluginId)
    }
    
    func attachToStramPluginRequestWith(sessionId: Int64, transactionId: String) -> URLRequest {
        let body = "{\"janus\":\"attach\",\"plugin\":\"janus.plugin.streaming\",\"transaction\":\"\(transactionId)\"}"
        
        return self.POSTRequestWith(body: body, sessionId: sessionId)
    }
    
    func createLongPollRequestWith(sessionId: Int64) -> URLRequest {
        let url = URL(string: baseUrl + "/" + String(describing: sessionId))!
        
        var request = URLRequest(url: url)
        
        request.httpMethod = "GET"
        
        return request
    }
    
    private func POSTRequestWith(body: String) -> URLRequest {
        return self.POSTRequestWith(body: body, sessionId: nil, pluginId: nil)
    }
    
    private func POSTRequestWith(body: String, sessionId: Int64?) -> URLRequest {
        return self.POSTRequestWith(body: body, sessionId: sessionId, pluginId: nil)
    }
    
    private func POSTRequestWith(body: String, sessionId: Int64?, pluginId: Int64?) -> URLRequest {
        let data = body.data(using: .utf8)
        
        return self.POSTRequestWith(body: data!, sessionId: sessionId, pluginId: pluginId)
    }
    
    private func POSTRequestWith(body: Data, sessionId: Int64?, pluginId: Int64?) -> URLRequest {
        var urlString = self.baseUrl
        
        if sessionId != nil {
            urlString = urlString + "/" + String(describing: sessionId!)
        }
        
        if pluginId != nil {
            urlString = urlString + "/" + String(describing: pluginId!)
        }
        
        let url = URL(string: urlString)!
        
        var request = URLRequest(url: url)
        
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("max-age=0", forHTTPHeaderField: "Cache-Control")
        request.httpMethod = "POST"
        
        request.httpBody = body
        
        return request
    }
}

public struct CreateSessionResponse: Decodable {
    let janus: String
    let transaction: String
    let data: ResponseData
    
    func isSuccessfull() -> Bool {
        return (self.janus == "success")
    }
}

public struct AttachToPluginResponse: Decodable {
    let janus: String
    let transaction: String
    let data: ResponseData
    
    func isSuccessfull() -> Bool {
        return (self.janus == "success")
    }
}

public struct ResponseData: Decodable {
    let id: Int64
}

public struct RTPForwardResponse: Decodable {
    let janus: String
    let transaction: String
    let sessionId: Int64
    let sender: Int64
    let plugindata: AudiobridgePluginData
    
    func isSuccessfull() -> Bool {
        return (self.janus == "success")
    }
    
    enum CodingKeys: String, CodingKey {
        case sessionId = "session_id"
        case janus
        case transaction
        case sender
        case plugindata
    }
}

public struct AudiobridgePluginData: Decodable {
    let plugin: String
    let data: AudiobridgePluginAdditionalData
}

public struct AudiobridgePluginAdditionalData: Decodable {
    let audiobridge: String
    let room: Int
    let streamId: Int64
    let host: String
    let port: UInt32
    
    enum CodingKeys: String, CodingKey {
        case audiobridge
        case room
        case streamId = "stream_id"
        case host
        case port
    }
}

public struct JanusEventWithJSEP: Decodable {
    let janus: String
    let session_id: Int64
    let transaction: String
    let sender: Int64
    let plugindata: StreamingPluginData
    let jsep: JanusJSEPData
}

public struct JanusEventWithTrickle: Codable {
    let janus: String
    let session_id: Int64
    let sender: Int64
    let candidate: JanusTrickleCandidate
}

public struct JanusTrickleLocalCandidate: Encodable {
    let janus: String
    let transaction: String
    let candidate: JanusTrickleCandidate
}

public struct JanusTrickleCandidate: Encodable, Decodable {
    public let sdpMid: String
    public let sdpMLineIndex: Int32
    public let candidate: String
}

public struct JanusJSEPData: Encodable, Decodable {
    let type: String
    let sdp: String
}

public struct JanusJSEPOUTPUTData: Codable {
    let type: String
    let sdp: String
}

public struct StreamingPluginData: Decodable {
    let plugin: String
    let data: StreamingPluginAdditionalData
}

public struct StreamingPluginAdditionalData: Decodable {
    let streaming: String
    let result: StreamingPluginStatus
}

public struct StreamingPluginStatus: Decodable {
    let status: String
}

public struct JanusMessageWithStartRequest: Encodable {
    let janus: String
    let transaction: String
    let body: JanusStartRequestBody
    let jsep: JanusJSEPData
}

public struct JanusOUTPUTMessageWithStartRequest: Encodable {
    let janus: String
    let transaction: String
    let body: JanusStartRequestBody
    let jsep: JanusJSEPOUTPUTData
}

public struct JanusStartRequestBody: Encodable {
    let request: String
}

public protocol JanusSessionDelegate: class {
    func offerReceived(sdp: String)
    func trickleReceived(trickle: JanusTrickleCandidate)
    func startingEventReceived()
}

public class JanusSession {
    private var requestBuilder: JanusRequestsBuilder
    private var sessionId: Int64?
    private var transactionId: String
    private var streamingPluginId: Int64?
    private var audionPluginId: Int64?
    
    public weak var delegate: JanusSessionDelegate?
    
    public init(url: String) {
        self.requestBuilder = JanusRequestsBuilder(url: url)
        self.transactionId = Utilites.randomString(length: 12)
    }
    
    public func CreaseStreamingPluginSession(completion: @escaping (Bool) -> ()) {
        let handler = completion
        
        // TODO: refactor this
        self.CreateJanusSession { result in
            if result {
                self.AttachToStreamingPlugin(completion: { result in
                    handler(result)
                })
                
            } else {
                handler(false)
            }
        }
    }
    
    private func CreateJanusSession(completion: @escaping (Bool) -> ()) {
        print("CreateJanusSession started")
        
        self.transactionId = Utilites.randomString(length: 12)
        
        let request = self.requestBuilder.createJanusSessionRequestWith(transactionId: self.transactionId)
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            
            let createResponse = self.proceedResponse(CreateSessionResponse.self, data, response, error)
            
            guard let result = createResponse else {
                completion(false)
                return
            }
            
            self.sessionId = result.data.id
            self.SendLongPollEventsHandler()
            completion(true)
        }
        
        task.resume()
    }
    
    private func SendLongPollEventsHandler() { // events handler and keep alive request simultaneously
        print("SendLongPollEventsHandler started")
        
        let request = self.requestBuilder.createLongPollRequestWith(sessionId: self.sessionId!)
        
        let task = URLSession.shared.dataTask(with: request) { data, _, _ in
            
            guard let data = data else {
                print("No data in LongPoll response")
                return
            }
            
            self.proceedLongPollResponseData(data)
            
            self.SendLongPollEventsHandler() // TODO: condition to stop!!!!
        }
        
        task.resume()
    }
    
    private func proceedLongPollResponseData(_ data: Data) {
        let responseString: String = String(data: data, encoding: .utf8)!
        
        print("EVENT HAVE COME: \(String(describing: responseString))")
        
        // TODO: we need better way to classify data type
        if responseString.contains("starting") {
            self.delegate?.startingEventReceived()
        }
        
        if responseString.contains("offer") {
            self.tryParseSEPOffer(data: data)
        }
        
        if responseString.contains("trickle") {
            self.tryParseTrickle(data: data)
        }
    }
    
    public func tryParseTrickle(data: Data) {
        guard let response: JanusEventWithTrickle = try? JSONDecoder().decode(JanusEventWithTrickle.self, from: data) else {
            print("json decode error")
            return
        }
        
        self.delegate?.trickleReceived(trickle: response.candidate)
    }
    
    public func tryParseSEPOffer(data: Data) {
        guard let response: JanusEventWithJSEP = try? JSONDecoder().decode(JanusEventWithJSEP.self, from: data) else {
            print("json decode error")
            return
        }
        
        self.delegate?.offerReceived(sdp: response.jsep.sdp)
    }
}

private typealias StreamingPlugin = JanusSession
public extension StreamingPlugin {
    private func AttachToStreamingPlugin(completion: @escaping (Bool) -> ()) {
        print("AttachToStreamingPlugin started")
        
        guard let sessionId = self.sessionId else {
            print("sessionID must not be null")
            return
        }
        
        self.transactionId = Utilites.randomString(length: 12)
        
        let request = self.requestBuilder.attachToStramPluginRequestWith(
            sessionId: sessionId,
            transactionId: self.transactionId
        )
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            
            let attachResponse = self.proceedResponse(AttachToPluginResponse.self, data, response, error)
            
            guard let result = attachResponse else {
                completion(false)
                return
            }
            
            if result.isSuccessfull() {
                self.streamingPluginId = result.data.id
                completion(true)
            }
        }
        
        task.resume()
    }
    
    func GetStreamsList(completion: @escaping (String?, Error?) -> ()) {
        print("AddStreamsList started")
        
        guard let sessionId = self.sessionId, let streamingPluginId = self.streamingPluginId else {
            let error = JanusWebGateError.runtimeError("Create sessing with attached streaming plugin firstr")
            completion(nil, error)
            return
        }
        
        self.transactionId = Utilites.randomString(length: 12)
        
        let request = self.requestBuilder.createGetStreamsListRequestWith(
            sessionId: sessionId,
            streamPluginId: streamingPluginId,
            transactionId: self.transactionId
        )
        
        let task = URLSession.shared.dataTask(with: request) { data, _, error in
            
            let responseString = String(data: data!, encoding: .utf8)
            print("responseString = \(String(describing: responseString))")
            
            // TODO: parse data
            completion(responseString, error)
            
            return
        }
        
        task.resume()
    }
    
    func SendWatchRequest(streamId: Int, completion: @escaping (Error?) -> ()) {
        print("SendWatchOffer started")
        
        guard let sessionId = self.sessionId, let streamingPluginId = self.streamingPluginId else {
            print("Create sessing with attached streaming plugin firstr")
            return
        }
        
        self.transactionId = Utilites.randomString(length: 12)
        
        let request = self.requestBuilder.createWatchOfferRequestWith(
            sessionId: sessionId,
            streamPluginId: streamingPluginId,
            transactionId: self.transactionId,
            streamId: streamId
        )
        
        self.SendSimpleRequest(request: request, completion: completion)
    }
    
    func SendStartCommand(sdp: String, completion: @escaping (Error?) -> ()) {
        print("SendStartCommand started")
        
        guard let sessionId = self.sessionId, let streamingPluginId = self.streamingPluginId else {
            print("Create sessing with attached streaming plugin firstr")
            return
        }
        
        self.transactionId = Utilites.randomString(length: 12)
        
        let request = self.requestBuilder.createStartCommandRequestWith(
            sessionId: sessionId,
            streamPluginId: streamingPluginId,
            transactionId: self.transactionId,
            sdp: sdp
        )
        
        self.SendSimpleRequest(request: request, completion: completion)
    }
    
    func SendLocalCandidate(candidate: String, sdpMLineIndex: Int32, sdpMid: String, completion: @escaping (Error?) -> ()) {
        print("SendLocalCandidate started")
        
        guard let sessionId = self.sessionId, let streamingPluginId = self.streamingPluginId else {
            print("Create sessing with attached streaming plugin firstr")
            return
        }
        
        self.transactionId = Utilites.randomString(length: 12)
        
        let request = self.requestBuilder.createTrickleCandidateRequestWith(
            sessionId: sessionId,
            streamPluginId: streamingPluginId,
            transactionId: self.transactionId,
            candidate: candidate,
            sdpMLineIndex: sdpMLineIndex,
            sdpMid: sdpMid
        )
        
        self.SendSimpleRequest(request: request, completion: completion)
    }
    
    func SendLocalCandidateComplete(completion: @escaping (Error?) -> ()) {
        print("SendLocalCandidateComplete started")
        
        guard let sessionId = self.sessionId, let streamingPluginId = self.streamingPluginId else {
            print("Create sessing with attached streaming plugin firstr")
            return
        }
        
        self.transactionId = Utilites.randomString(length: 12)
        
        let request = self.requestBuilder.createLocalCandidateCompleteRequestWith(
            sessionId: sessionId,
            streamPluginId: streamingPluginId,
            transactionId: self.transactionId
        )
        
        self.SendSimpleRequest(request: request, completion: completion)
    }
    
    func SendReStartPausedStreamCommand(completion: @escaping (Error?) -> ()) {
        print("SendReStartPausedStreamCommand started")
        
        guard let sessionId = self.sessionId, let streamingPluginId = self.streamingPluginId else {
            print("Create sessing with attached streaming plugin firstr")
            return
        }
        
        self.transactionId = Utilites.randomString(length: 12)
        
        let request = self.requestBuilder.createRestartActiveStreamRequestWith(
            sessionId: sessionId,
            streamPluginId: streamingPluginId,
            transactionId: self.transactionId
        )
        
        self.SendSimpleRequest(request: request, completion: completion)
    }
    
    func SendPauseStreamCommand(completion: @escaping (Error?) -> ()) {
        print("SendPauseStreamCommand started")
        
        guard let sessionId = self.sessionId, let streamingPluginId = self.streamingPluginId else {
            print("Create sessing with attached streaming plugin firstr")
            return
        }
        
        self.transactionId = Utilites.randomString(length: 12)
        
        let request = self.requestBuilder.createPauseActiveStreamRequestWith(
            sessionId: sessionId,
            streamPluginId: streamingPluginId,
            transactionId: self.transactionId
        )
        
        self.SendSimpleRequest(request: request, completion: completion)
    }
    
    func SendStopStreamCommand(completion: @escaping (Error?) -> ()) {
        print("SendStopStreamCommand started")
        
        guard let sessionId = self.sessionId, let streamingPluginId = self.streamingPluginId else {
            print("Create sessing with attached streaming plugin firstr")
            return
        }
        
        self.transactionId = Utilites.randomString(length: 12)
        
        let request = self.requestBuilder.createStopActiveStreamRequestWith(
            sessionId: sessionId,
            streamPluginId: streamingPluginId,
            transactionId: self.transactionId
        )
        
        self.SendSimpleRequest(request: request, completion: completion)
    }
    
    private func SendSimpleRequest(request: URLRequest, completion: @escaping (Error?) -> ()) {
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            // TODO: Expecting starting in long poll
            let error = self.isResponseCorrect(data, response as? HTTPURLResponse, error)
            completion(error)
            return
        }
        
        task.resume()
    }
    
//    public func GetStreamInfo(streamId: Int, secret: String, completion: @escaping (Bool) -> ())
//    {
//        print("GetStreamInfo started")
//
//        let urlString = baseUrl + "\(self.sessionId)/\(self.streamingPluginId)"
//        let url = URL(string: urlString)!
//
//        var request = URLRequest(url: url)
//
//        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
//        request.httpMethod = "POST"
//
//        let body = "{\"request\" : \"info\", \"id\" : \(streamId), \"secret\" : \"\(secret)\"}";
//        let rBody = "{\"janus\":\"message\", \"transaction\":\"\(TransactionId)\", \"body\" : \(body) }"
//
//        request.httpBody = rBody.data(using: .utf8)
//
//        let task = URLSession.shared.dataTask(with: request) { data, response, error in
//            guard let data = data, error == nil else {
//                // check for fundamental networking error
//                print("error=\(String(describing: error))")
//                return
//            }
//
//            if (!self.CheckResponseForHttpErrors(response: response as? HTTPURLResponse))
//            {
//                return //TODO: throw some exception
//            }
//
//            let responseString = String(data: data, encoding: .utf8)
//            print("responseString = \(String(describing: responseString))")
//
//            completion(true)
//
//            print("GetStreamInfo finished")
//
//            return
//
//        }
//
//        task.resume()
//    }
}

private typealias RequestsProcessing = JanusSession
public extension RequestsProcessing {
    private func proceedResponse<T: Decodable>(_ dump: T.Type, _ data: Data?, _ response: URLResponse?, _ error: Error?) -> T? {
        guard let data = data else {
            return nil
        }
        
        let responseString = String(data: data, encoding: .utf8)
        print("responseString = \(String(describing: responseString))")
        
        guard let result = try? JSONDecoder().decode(T.self, from: data) else {
            print("json decode error")
            return nil
        }
        
        return result
    }
    
    private func isResponseCorrect(_ data: Data?, _ response: HTTPURLResponse?, _ error: Error?) -> Error? {
        if error != nil {
            return error
        }
        
        if response == nil || data == nil {
            return JanusWebGateError.runtimeError("Network errror, unexpected response format")
        }
        
        if response!.statusCode < 200 || response!.statusCode >= 300 {
            return JanusWebGateError.runtimeError("Network errror, unexpected status code: \(response!.statusCode)")
        }
        
        return nil
    }
}

// private typealias AudioBridgePlugin = JanusSession
// public extension AudioBridgePlugin
// {
//
//    public func GetRoomInfo(roomId : Int64, secret : String, completion: @escaping (Bool) -> ())
//    {
//        print("GetRoomInfo started")
//
//        let urlString = baseUrl + "\(self.sessionId)/\(self.audionPluginId)"
//        let url = URL(string: urlString)! //TODO: sessionId must exist, chex url syntax
//
//        var request = URLRequest(url: url)
//
//        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
//        request.httpMethod = "POST"
//
//        let body = "{\"request\":\"info\",\"id\":\(roomId),\"secret\": \"\(secret)\"}"
//        let rBody = "{\"janus\":\"message\", \"transaction\":\"\(TransactionId)\", \"body\" : \(body) }"
//
//        request.httpBody = rBody.data(using: .utf8)
//
//        let task = URLSession.shared.dataTask(with: request) { data, response, error in
//            guard let data = data, error == nil else {
//                // check for fundamental networking error
//                print("error=\(String(describing: error))")
//                return
//            }
//
//            if (!self.CheckResponseForHttpErrors(response: response as? HTTPURLResponse))
//            {
//                return //TODO: throw some exception
//            }
//
//            let responseString = String(data: data, encoding: .utf8)
//            print("responseString = \(String(describing: responseString))")
//
//            //            guard let response = try? JSONDecoder().decode(CreateSessionResponse.self, from: data) else
//            //            {
//            //                print("json decode error")
//            //                return
//            //            }
//            //
//            //            if (response.isSuccessfull())
//            //            {
//            //            }
//
//            print("GetRoomInfo finished")
//            completion(true)
//            return
//
//        }
//
//        task.resume()
//    }
//
//    public func AddNewRTPForwarder(host : String, port : UInt32, roomId : Int, secret : String, completion: @escaping (RTPForwardResponse) -> ())
//    {
//        print("AddNewRTPForwarder started")
//
//        let urlString = baseUrl + "\(self.sessionId)/\(self.audionPluginId)"
//        let url = URL(string: urlString)! //TODO: sessionId must exist, chex url syntax
//
//        var request = URLRequest(url: url)
//
//        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
//        request.httpMethod = "POST"
//
//        let body = "{\"request\" : \"rtp_forward\", \"room\" : \(roomId), \"host\" : \"\(host)\",\"port\" : \(port),\"always_on\" : true,\"secret\" : \"\(secret)\"}";
//        let rBody = "{\"janus\":\"message\", \"transaction\":\"\(TransactionId)\", \"body\" : \(body) }"
//
//        request.httpBody = rBody.data(using: .utf8)
//
//        let task = URLSession.shared.dataTask(with: request) { data, response, error in
//            guard let data = data, error == nil else {
//                // check for fundamental networking error
//                print("error=\(String(describing: error))")
//                return
//            }
//
//            if (!self.CheckResponseForHttpErrors(response: response as? HTTPURLResponse))
//            {
//                return //TODO: throw some exception
//            }
//
//            let responseString = String(data: data, encoding: .utf8)
//            print("responseString = \(String(describing: responseString))")
//
//            guard let response = try? JSONDecoder().decode(RTPForwardResponse.self, from: data) else
//            {
//                print("json decode error")
//                return
//            }
//
//            if (response.isSuccessfull())
//            {
//                completion(response)
//            }
//
//            print("AddNewRTPForwarder finished")
//
//            return
//
//        }
//
//        task.resume()
//    }
//
//    public func GetForwardersList(roomId : Int, secret: String)
//    {
//        print("GetForwardersList started")
//
//        let urlString = baseUrl + "\(self.sessionId)/\(self.audionPluginId)"
//        let url = URL(string: urlString)! //TODO: sessionId must exist, chex url syntax
//
//        var request = URLRequest(url: url)
//
//        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
//        request.httpMethod = "POST"
//
//        let body = "{\"request\" : \"listforwarders\",\"room\" : \(roomId), \"secret\" : \"\(secret)\"}"
//        let rBody = "{\"janus\":\"message\", \"transaction\":\"\(TransactionId)\", \"body\" : \(body) }"
//
//        request.httpBody = rBody.data(using: .utf8)
//
//        let task = URLSession.shared.dataTask(with: request) { data, response, error in
//            guard let data = data, error == nil else {
//                // check for fundamental networking error
//                print("error=\(String(describing: error))")
//                return
//            }
//
//            if (!self.CheckResponseForHttpErrors(response: response as? HTTPURLResponse))
//            {
//                return //TODO: throw some exception
//            }
//
//            let responseString = String(data: data, encoding: .utf8)
//            print("responseString = \(String(describing: responseString))")
//
//
//            print("GetForwardersList finished")
//
//            return
//
//        }
//
//        task.resume()
//    }
//
//
//    public func GetAudioStreamingsList(completion: @escaping (Bool) -> ())
//    {
//        print("GetStreamingsList started")
//
//        let urlString = baseUrl + "\(self.sessionId)/\(self.audionPluginId)"
//        let url = URL(string: urlString)! //TODO: sessionId must exist, chex url syntax
//
//        var request = URLRequest(url: url)
//
//        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
//        request.httpMethod = "POST"
//
//        let body = "{\"janus\":\"message\", \"transaction\":\"\(TransactionId)\", \"body\" : {\"request\" : \"list\"} }"
//
//        request.httpBody = body.data(using: .utf8)
//
//        let task = URLSession.shared.dataTask(with: request) { data, response, error in
//            guard let data = data, error == nil else {
//                // check for fundamental networking error
//                print("error=\(String(describing: error))")
//                return
//            }
//
//            if (!self.CheckResponseForHttpErrors(response: response as? HTTPURLResponse))
//            {
//                return //TODO: throw some exception
//            }
//
//            let responseString = String(data: data, encoding: .utf8)
//            print("responseString = \(String(describing: responseString))")
//
//            //            guard let response = try? JSONDecoder().decode(CreateSessionResponse.self, from: data) else
//            //            {
//            //                print("json decode error")
//            //                return
//            //            }
//            //
//            //            if (response.isSuccessfull())
//            //            {
//            //            }
//
//            print("GetStreamingsList finished")
//            completion(true)
//            return
//
//        }
//
//        task.resume()
//    }
//
//
//    public func AttachToAudioBridgePlugin(completion: @escaping (Bool) -> ())
//    {
//        print("AttachToAudioBridgePlugin started")
//
//        let url = URL(string: baseUrl + String(describing: self.sessionId))! //TODO: sessionId must exist, chex url syntax
//
//        var request = URLRequest(url: url)
//
//        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
//        request.httpMethod = "POST"
//
//        let body = "{\"janus\":\"attach\",\"plugin\":\"janus.plugin.audiobridge\",\"transaction\":\"\(TransactionId)\"}"
//
//        request.httpBody = body.data(using: .utf8)
//
//        let task = URLSession.shared.dataTask(with: request) { data, response, error in
//            guard let data = data, error == nil else {
//                // check for fundamental networking error
//                print("error=\(String(describing: error))")
//                return
//            }
//
//            if (!self.CheckResponseForHttpErrors(response: response as? HTTPURLResponse))
//            {
//                completion(false) //TODO: throw some exception
//            }
//
//            let responseString = String(data: data, encoding: .utf8)
//            print("responseString = \(String(describing: responseString))")
//
//            guard let response = try? JSONDecoder().decode(AttachToPluginResponse.self, from: data) else
//            {
//                print("json decode error")
//                return
//            }
//
//            if (response.isSuccessfull())
//            {
//                self.audionPluginId = response.data.id
//                completion(true)
//            }
//
//            print("AttachToAudioBridgePlugin finished")
//
//        }
//
//        task.resume()
//    }

// }
