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

open class RESTClient {
    
    public static var defaultClient: RESTClient?
    
    public var additionalHeaders: HTTPHeaders?
    
    private let servicePath: String
    private let sessionManager: SessionManager
    
    // MARK: Public Methods
    
    public init(servicePath: String) {
        self.servicePath = servicePath
        self.sessionManager = Alamofire.SessionManager.default
    }
    
    public func get(at path: String, requestData: JSONParameters? = nil, completion: RESTClientCompletion? = nil) {
        self.request(at: path, requestData: requestData, completion: completion)
    }
    
    public func post(at path: String, requestData: JSONParameters? = nil, completion: RESTClientCompletion? = nil) {
        self.request(at: path,
                     method: .post,
                     requestData: requestData,
                     encoding:JSONEncoding.default,
                     completion: completion)
    }
    
    public func put(at path: String, requestData: JSONParameters? = nil, completion: RESTClientCompletion? = nil) {
        self.request(at: path,
                     method: .put,
                     requestData: requestData,
                     encoding:JSONEncoding.default,
                     completion: completion)
    }
    
    public func delete(at path: String, requestData: JSONParameters? = nil, completion: RESTClientCompletion? = nil) {
        self.request(at: path,
                     method: .delete,
                     requestData: requestData,
                     encoding:JSONEncoding.default,
                     completion: completion)
    }
    
    public func request(at path: String,
                        method: HTTPMethod = .get,
                        requestData: JSONParameters? = nil,
                        encoding: ParameterEncoding = URLEncoding.default,
                        completion: RESTClientCompletion? = nil) {
        self.sessionManager.request(self.makeAbsolutePath(path),
                                    method: method,
                                    parameters: requestData,
                                    encoding: encoding,
                                    headers: self.additionalHeaders).validate().responseJSON { response in
                                        self.handleResponse(response, completion: completion)
        }
    }
    
    public func upload(image: UIImage,
                       imageType: ImageType = .jpeg,
                       to path: String,
                       parameters: FormDataParameters? = nil,
                       method: HTTPMethod = .post,
                       completion: RESTClientCompletion? = nil) {
        
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
                                         fileName: "img.jpeg", mimeType: "image/jpeg")
            }
        }
        
        self.sessionManager.upload(multipartFormData: multipartFormData,
                                   to: self.makeAbsolutePath(path),
                                   method: method,
                                   headers: self.additionalHeaders) { encodingCompletionResult in
                                    switch encodingCompletionResult {
                                    case .success(let request, _, _):
                                        request.responseJSON(completionHandler: { response in
                                            self.handleResponse(response, completion: completion)
                                        })
                                    case .failure(let error):
                                        if let safeCompletion = completion {
                                            safeCompletion(false, nil, error)
                                        }
                                        
                                    }
        }
        
    }
    
    // MARK: Private Methods
    
    private func makeAbsolutePath(_ path: String) -> String {
        let absolutePath = "\(self.servicePath)\(path)"
        return absolutePath
    }
    
    private func handleResponse(_ response: DataResponse<Any>, completion: RESTClientCompletion?) {
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
    
}
