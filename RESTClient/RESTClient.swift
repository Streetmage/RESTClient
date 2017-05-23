//
//  RESTClient.swift
//  RESTClient
//
//  Created by Evgeny Kubrakov on 07.03.17.
//  Copyright © 2017 Evgeny Kubrakov. All rights reserved.
//

import UIKit
import Alamofire

public typealias FormDataParameters = [String : String]
public typealias JSONParameters = [String : Any]
public typealias JSONDictionary = JSONParameters
public typealias JSONArray = Array<JSONParameters>

public typealias RESTClientCompletion = (_ success: Bool, _ responseData: JSONParcelable?, _ error: Error?) -> Void
public typealias ProgressHandler = (_ fractionCompleted: Double) -> Void

open class RESTClient {
    
    public static var isLoggingEnabled = false
    
    public static var defaultClient: RESTClient?
    
    public var additionalHeaders: HTTPHeaders?
    
    private let servicePath: String
    private let sessionManager: SessionManager
    
    // MARK: Public Methods
    
    public init(servicePath: String) {
        self.servicePath = servicePath
        self.sessionManager = Alamofire.SessionManager.default
    }
    
    public func get(at path: String,
                    requestData: JSONParameters? = nil,
                    requestHeaders: HTTPHeaders? = nil,
                    needsJSONParsing: Bool = true,
                    completion: RESTClientCompletion? = nil) {
        
        self.request(at: path,
                     requestData: requestData,
                     requestHeaders: requestHeaders,
                     needsJSONParsing: needsJSONParsing,
                     completion: completion)
    }
    
    public func post(at path: String,
                     requestData: JSONParameters? = nil,
                     requestHeaders: HTTPHeaders? = nil,
                     needsJSONParsing: Bool = true,
                     completion: RESTClientCompletion? = nil) {
        
        self.request(at: path,
                     method: .post,
                     requestData: requestData,
                     requestHeaders: requestHeaders,
                     needsJSONParsing: needsJSONParsing,
                     encoding:JSONEncoding.default,
                     completion: completion)
    }
    
    public func put(at path: String,
                    requestData: JSONParameters? = nil,
                    requestHeaders: HTTPHeaders? = nil,
                    needsJSONParsing: Bool = true,
                    completion: RESTClientCompletion? = nil) {
        
        self.request(at: path,
                     method: .put,
                     requestData: requestData,
                     requestHeaders: requestHeaders,
                     needsJSONParsing: needsJSONParsing,
                     encoding:JSONEncoding.default,
                     completion: completion)
    }
    
    public func delete(at path: String,
                       requestData: JSONParameters? = nil,
                       requestHeaders: HTTPHeaders? = nil,
                       needsJSONParsing: Bool = true,
                       completion: RESTClientCompletion? = nil) {
        
        self.request(at: path,
                     method: .delete,
                     requestData: requestData,
                     requestHeaders: requestHeaders,
                     needsJSONParsing: needsJSONParsing,
                     encoding:JSONEncoding.default,
                     completion: completion)
    }
    
    public func request(at path: String,
                        method: HTTPMethod = .get,
                        requestData: JSONParameters? = nil,
                        requestHeaders: HTTPHeaders? = nil,
                        needsJSONParsing: Bool = true,
                        encoding: ParameterEncoding = URLEncoding.default,
                        completion: RESTClientCompletion? = nil) {
        
        if (RESTClient.isLoggingEnabled) {
            printLog(with: "Request", method: method, path: path, parameters: requestData)
        }
        
        var headers = self.additionalHeaders
        if let safeRequestHeaders = requestHeaders {
            headers = headers != nil ? headers?.merged(with: safeRequestHeaders) : safeRequestHeaders
        }
        
        let request = self.sessionManager.request(self.makeAbsolutePath(path),
                                                  method: method,
                                                  parameters: requestData,
                                                  encoding: encoding,
                                                  headers: headers)
        request.validate()
        
        if needsJSONParsing {
            request.responseJSON { response in
                self.handleJSONResponse(response, completion: completion)
            }
        } else {
            request.response { response in
                self.handleDefaultDataResponse(response, completion: completion)
            }
        }
    }
    
    public func upload(image: UIImage,
                       imageType: ImageType = .jpeg,
                       to path: String,
                       parameters: FormDataParameters? = nil,
                       method: HTTPMethod = .post,
                       completion: RESTClientCompletion? = nil) {
        
        if (RESTClient.isLoggingEnabled) {
            printLog(with: "Upload", method: method, path: path, parameters: parameters)
        }
        
        var imageData: Data? = nil
        switch imageType {
        case .jpeg:
            imageData = UIImageJPEGRepresentation(image, 1.0)
        case .png:
            imageData = UIImagePNGRepresentation(image)
        }
        
        let multipartFormData = { (multipartFormData: MultipartFormData) in
            
            if let safeImageData = imageData {
                if let safeParameters = parameters {
                    for (key, value) in safeParameters {
                        multipartFormData.append(value.data(using: .utf8)!, withName: key)
                    }
                }
                multipartFormData.append(safeImageData,
                                         withName: "img",
                                         fileName: "img.jpeg",
                                         mimeType: "image/jpeg")
            }
        }
        
        self.sessionManager.upload(multipartFormData: multipartFormData,
                                   to: self.makeAbsolutePath(path),
                                   method: method,
                                   headers: self.additionalHeaders) { encodingCompletionResult in
                                    switch encodingCompletionResult {
                                    case .success(let request, _, _):
                                        request.responseJSON(completionHandler: { response in
                                            self.handleJSONResponse(response, completion: completion)
                                        })
                                    case .failure(let error):
                                        if let safeCompletion = completion {
                                            safeCompletion(false, nil, error)
                                        }
                                        
                                    }
        }
        
    }
    
    public func upload(videoFileURL: URL,
                       videoDataType: String,
                       to path: String,
                       jsonParameters: JSONParameters?,
                       jsonParametersTitle: String?,
                       method: HTTPMethod = .post,
                       progressHandler: ProgressHandler? = nil,
                       completion: RESTClientCompletion? = nil) {
        
        if (RESTClient.isLoggingEnabled) {
            printLog(with: "Upload", method: method, path: path, parameters: jsonParameters)
        }
        
        let multipartFormData = { (multipartFormData: MultipartFormData) in
            
            if let safeJSONParameters = jsonParameters, let safeJSONParametersTitle = jsonParametersTitle {
                if let jsonData = try? JSONSerialization.data(withJSONObject:safeJSONParameters, options: .prettyPrinted) {
                    multipartFormData.append(jsonData, withName: safeJSONParametersTitle, mimeType:"application/json")
                }
            }
            
            multipartFormData.append(videoFileURL,
                                     withName: "video",
                                     fileName: "video.\(videoDataType)",
                mimeType: "application/octet-stream")
        }
        
        self.sessionManager.upload(multipartFormData: multipartFormData,
                                   to: self.makeAbsolutePath(path),
                                   method: method,
                                   headers: self.additionalHeaders,
                                   encodingCompletion: { encodingCompletionResult in
                                    
                                    switch encodingCompletionResult {
                                    case .success(let request, _, _):
                                        request.validate().responseJSON(completionHandler: { response in
                                            self.handleJSONResponse(response, completion: completion)
                                        })
                                        request.uploadProgress { progress in
                                            progressHandler?(progress.fractionCompleted)
                                        }
                                    case .failure(let error):
                                        if let safeCompletion = completion {
                                            safeCompletion(false, nil, error)
                                        }
                                        
                                    }
        })
    }
    
    // MARK: Private Methods
    
    private func makeAbsolutePath(_ path: String) -> String {
        let absolutePath = "\(self.servicePath)\(path)"
        return absolutePath
    }
    
    private func handleJSONResponse(_ response: DataResponse<Any>, completion: RESTClientCompletion?) {
        if let safeCompletion = completion {
            switch response.result {
            case .success:
                self.handleSuccessfulCompletion(with: response.result.value,
                                                completion: safeCompletion)
            case .failure(let error):
                safeCompletion(false, nil, error)
                
            }
        }
    }
    
    private func handleDefaultDataResponse(_ response: DefaultDataResponse, completion: RESTClientCompletion?) {
        if let safeCompletion = completion {
            let error = response.error
            safeCompletion(error == nil, nil, error)
        }
    }
    
    private func handleSuccessfulCompletion(with resultValue: Any?, completion: RESTClientCompletion) {
        
        var result: JSONParcelable?
        var error: RESTClientError?
        
        if resultValue != nil {
            
            if let parcelableResult = resultValue as? JSONArray {
                result = parcelableResult
            }
            else if let parcelableResult = resultValue as? JSONDictionary {
                result = parcelableResult
            } else {
                error = .resultIsNotValidJSON
            }
            
        }
        
        completion(error == nil, result, error)
        
    }
    
    private func printLog(with title: String, method: HTTPMethod, path: String, parameters: Any?) {
        print("\n------------------\(title)---------------------\n\n" +
            "\(method.rawValue) \(self.makeAbsolutePath(path))\n\n" +
            "Parameters: \(String(describing: parameters))" +
            "\n\n=============================================\n")
    }
    
}
