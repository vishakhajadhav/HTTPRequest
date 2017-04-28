  //
//  HTTPRequest.swift
// Generic
//
//  Created by KahunaOSx on 1/28/16.
//  Copyright © 2016 Kahuna Systems Pvt. Ltd. All rights reserved.
//

import UIKit
import Alamofire

public protocol HTTPRequestDelegate : class {
    
      func httpRequest(requestHandler: HTTPRequest, requestCompletedWithResponseJsonObject jsonObject: AnyObject, forPath path:String);
      func httpRequest(requestHandler: HTTPRequest, requestFailedWithError failureError: Error, forPath path:String);
}

public class HTTPRequest
{
    enum ServerResponseCodes: Int
    {
        case successCode = 200
        case unknownErrorCode = 1000
    }
    enum UnidentifiedError: Error {
        case emptyHTTPResponse
    }
    //static let sharedInstance = HTTPRequest()
    /*public weak var delegate : HTTPRequestDelegate?
    var alamofireManager = Alamofire.SessionManager.default*/
    
    public static let sharedInstance = HTTPRequest()
    weak var delegate: HTTPRequestDelegate?
    var alamofireManager = Alamofire.SessionManager.default
    public struct APIManager {
        public static let sharedManager = { () -> SessionManager in
            let configuration = URLSessionConfiguration.default
            return SessionManager(configuration: configuration)
        }()
    }
    public init(){
    }
    
    // MARK: - POST TO PATH
    /**
     Creates a POST request for the specified URL Path, parameters, and for time out interval.
     - parameter URLString:  The URL string.
     - parameter parameters: The parameters.
     - parameter timeoutInterval: The Request time out interval.
     - parameter userName: The Username.
     - parameter endpointName: The endpointName.
     */
    public func sendRequestAtPath(_ path: String, withParameters parameters: [String: AnyObject]?, timeoutInterval interval: Int, andToken token: String, userName: String, endpointName: String) {
        let requestStartTime = self.getCurrentDate()
        var requestString = ""
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: parameters!, options: JSONSerialization.WritingOptions.prettyPrinted)
            let jsonString = NSString(data: jsonData, encoding: String.Encoding.utf8.rawValue)! as String
            print("\n\n Request : \(jsonString)")
            requestString = "Request : \(jsonString)"
        } catch let error as NSError {
            print(error)
        }
        self.alamofireManager.session.configuration.timeoutIntervalForRequest = TimeInterval(interval) // seconds
        self.alamofireManager.session.configuration.timeoutIntervalForResource = TimeInterval(interval)
        self.alamofireManager.session.configuration.httpMaximumConnectionsPerHost = 10
        var tokenToSet = ""
        if  token.characters.count > 0 {
            tokenToSet = String(format: "token%@", token)
            print(tokenToSet)
        }
        var authheader:[String:String]? = nil
        if tokenToSet.characters.count > 0 {
            authheader = [ "Authorization": tokenToSet]
        }
        
       APIManager.sharedManager.request(path, method: .post, parameters: parameters, encoding: JSONEncoding.default, headers: authheader) .downloadProgress { progress in
            let percent = progress.completedUnitCount / progress.totalUnitCount
            print("percent DataReceived=============> \(percent)")
            
            }
            .responseJSON { response in
                let responseReceiveTime = self.getCurrentDate()
                let responseData = response.data as NSData?
                let resultText = NSString(data: response.data!, encoding: String.Encoding.utf8.rawValue)
                print("\nPath :\(path) \n\n\(requestString)\n\nResponse :\(resultText)\n\n")
                let responseString = ("\n\nResponse :\(resultText)\n\n")
                if responseData == nil {
                 self.sendDeviceLogsToServer(request: requestString, with:"Response is nil", urlPath: path, erroCode:Double(ServerResponseCodes.unknownErrorCode.rawValue), userName: userName, endPointName: endpointName)
                    self.handleError(error: UnidentifiedError.emptyHTTPResponse, forPath: path)
                }
                else if let error = response.error{
                    self.sendDeviceLogsToServer(request: requestString, with:error.localizedDescription, urlPath: path, erroCode: Double(ServerResponseCodes.unknownErrorCode.rawValue),userName: userName, endPointName: endpointName)
                    self.handleError(error: error, forPath: path)
                }else{
                    do {
                        let responseParseTime = self.getCurrentDate()
                        let jsonObject = try JSONSerialization.jsonObject(with: responseData! as Data, options:JSONSerialization.ReadingOptions(rawValue: 0))
                        let checkReponseData:CheckResponseFormat = CheckResponseFormat(fromDictionary: jsonObject as! NSDictionary)
                        /** SEND LOGS TO SERVER IF ERROR CODE IS NOT 200 */
                        if checkReponseData.result == nil
                        {
                            self.sendDeviceLogsToServer(request: requestString, with: responseString, urlPath: path, erroCode: Double(ServerResponseCodes.unknownErrorCode.rawValue), userName: userName, endPointName: endpointName)
                        }
                        else if checkReponseData.result.code != ServerResponseCodes.successCode.rawValue {
                            // SEND DEVICE LOGS TO KAHUNA SERVER
                            self.sendDeviceLogsToServer(request: requestString, with: responseString, urlPath: path, erroCode: Double(checkReponseData.result.code), userName: userName, endPointName: endpointName)
                        }
                        let code = checkReponseData.result.code
                        // SEND TIME STAMP VALUES TO KAHUNA SERVER
                        if jsonObject is NSDictionary {
                            let jsonObjectDict = jsonObject as? NSDictionary
                            var responseStatus = "Success"
                            if code != ServerResponseCodes.successCode.rawValue {
                                responseStatus = "Failure"
                            }
                            let formatter = DateFormatter()
                            formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
                            var requestInTime = formatter.string(from: Date())
                            var requestOutTime = formatter.string(from: Date())
                            if let time = jsonObjectDict?["requestInTime"] {
                                requestInTime = String(format: "%@", (time as? String)!) // time as! String
                            }
                            if let otime = jsonObjectDict?["requestOutTime"] {
                                requestOutTime = String(format: "%@", (otime as? String)!)
                            }
                            self.sendTimeStampLogsToServer(path, responseStatus: responseStatus, mobileReqStart: requestStartTime, mobileResponseReceive: responseReceiveTime, mobileServiceParse: responseParseTime, serverRequestReceive: requestInTime, serverResponseStart: requestOutTime)
                        }
                        self.handleResponse(jsonResponse: jsonObject as AnyObject, forPath: path)
                    }
                    catch let JSONError as NSError {
                        self.handleError(error: JSONError, forPath: path)
                    }
                }
        }
    }
    
    // MARK: - GET TO PATH
    /**
     Creates a GET request for the specified URL Path, parameters, and for time out interval.
     - parameter URLString:  The URL string.
     - parameter parameters: The parameters.
     - parameter timeoutInterval: The Request time out interval.
     */
    public func sendGetRequestAtPath(_ path: String, withParameters parameters: [String: AnyObject]?, timeoutInterval interval: Int, userName: String, endpointName: String) {
        print("\n\nURL: \(path)")
        APIManager.sharedManager.request(path, method: .get, parameters: parameters, encoding: JSONEncoding.default, headers: nil).responseJSON { response in
            let responseData = response.data as Data?
            let resultText = NSString(data: responseData!, encoding: String.Encoding.utf8.rawValue)
            print("GET Result :\(resultText)")
            if responseData == nil {
                self.handleError(error: UnidentifiedError.emptyHTTPResponse, forPath: path)
                // SEND DEVICE LOGS TO KAHUNA SERVER
                self.sendDeviceLogsToServer(request: path, with: "Response is nil", urlPath: path, erroCode: Double(ServerResponseCodes.unknownErrorCode.rawValue), userName: userName, endPointName: endpointName)
                self.handleError(error: UnidentifiedError.emptyHTTPResponse, forPath: path)
            }
            if  response.error != nil  {
                // SEND DEVICE LOGS TO KAHUNA SERVER
                self.sendDeviceLogsToServer(request: path, with: response.error?.localizedDescription, urlPath: path, erroCode: Double(ServerResponseCodes.unknownErrorCode.rawValue), userName: userName, endPointName: endpointName)
                self.handleError(error: response.error!, forPath: path)
            }
            do {
                let jsonObject = try JSONSerialization.jsonObject(with: responseData!, options: JSONSerialization.ReadingOptions(rawValue: 0))
                self.handleResponse(jsonResponse: jsonObject as AnyObject, forPath: path)
            } catch let JSONError as NSError {
                print(JSONError)
                self.handleError(error: JSONError, forPath: path)
            }
        }
    }
    
    // MARK: - MULTIPART TO PATH
    /**
     Creates a MULTIPART request for the specified URL Path, imagePaths, parameters, and for time out interval.
     - parameter URLString:  The URL string.
     - parameter parameters: The parameters.
     - parameter imagePaths: The image path array.
     - parameter timeoutInterval: The Request time out interval.
     */
    public func sendMultipartRequestAtPath(_ path: String, withImagePaths imagePaths: [String], andParameters parameters: [String: AnyObject]?, timeoutInterval interval: Int, userToken: String, uploadImageKeyName: String, imageUploadJSONName: String, userName: String, endPointName: String) {
        let requestStartTime = self.getCurrentDate()
        print("\n\nURL: \(path)")
        var jsonRequest = ""
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: parameters!, options: JSONSerialization.WritingOptions.prettyPrinted)
            let jsonString = NSString(data: jsonData, encoding: String.Encoding.utf8.rawValue)! as String
            print("\n\n Request : \(jsonString)")
            jsonRequest = jsonString
        } catch let error as NSError {
            self.handleError(error: error, forPath: path)
        }
        print(jsonRequest)
        let requestString = "\n\nRequest :\(jsonRequest)\n\n"
        var tokenToSet = ""
        //let userDefault = UserDefaults.standard
        if userToken.characters.count > 0 {
            tokenToSet = String(format: "token%@", userToken)
            print(tokenToSet)
        }
        let authheader = ["Authorization": tokenToSet]
        self.alamofireManager.session.configuration.timeoutIntervalForRequest = TimeInterval(interval) // seconds
        self.alamofireManager.session.configuration.timeoutIntervalForResource = TimeInterval(interval)
        //  let urlPath = URL(string: path)
        let urlPath = try! URLRequest(url: path, method: .post, headers: authheader)
        Alamofire.upload(multipartFormData: { (multipartFormData) in
            for imagePath in imagePaths {
                multipartFormData.append(URL(fileURLWithPath: imagePath), withName: uploadImageKeyName)
            }
            multipartFormData.append(jsonRequest.data(using: String.Encoding.utf8, allowLossyConversion: false)!, withName:imageUploadJSONName)
        }, with: urlPath, encodingCompletion: { (result) in
            switch result {
            case .failure(let encodingError):
                self.handleError(error: encodingError, forPath: path)
                break
            case .success(let upload, _, _):
                upload.responseJSON { response in
                    let responseReceiveTime = self.getCurrentDate()
                    let responseData = response.data as Data?
                    let resultText = NSString(data: responseData!, encoding: String.Encoding.utf8.rawValue)
                    // if(resultText?.length < 1000) {
                    print("\nPath :\(path) \n\n\(requestString)\n\nResponse :\(resultText)\n\n")
                    let responseString = "\n\nResponse :\(resultText)\n\n"
                    if responseData == nil {
                        // SEND DEVICE LOGS TO KAHUNA SERVER
                        self.sendDeviceLogsToServer(request: requestString, with: "Response is nil", urlPath: path, erroCode: Double(ServerResponseCodes.unknownErrorCode.rawValue), userName: userName, endPointName: endPointName)
                        self.handleError(error: UnidentifiedError.emptyHTTPResponse, forPath: path)
                    }
                    else if let error = response.error {
                        // SEND DEVICE LOGS TO KAHUNA SERVER
                        self.sendDeviceLogsToServer(request: requestString, with: error.localizedDescription, urlPath: path, erroCode: Double(ServerResponseCodes.unknownErrorCode.rawValue), userName: userName, endPointName: endPointName)
                        self.handleError(error: error, forPath: path)
                    }
                    else {
                        do {
                            let jsonObject = try JSONSerialization.jsonObject(with: responseData!, options: JSONSerialization.ReadingOptions(rawValue: 0))
                            let responseParseTime = self.getCurrentDate()
                            let checkReponseData: CheckResponseFormat = CheckResponseFormat(fromDictionary: (jsonObject as? NSDictionary)!)
                            /** SEND LOGS TO SERVER IF ERROR CODE IS NOT 200 */
                            if checkReponseData.result == nil {
                                // SEND DEVICE LOGS TO KAHUNA SERVER
                                self.sendDeviceLogsToServer(request: requestString, with: responseString, urlPath: path, erroCode: Double(ServerResponseCodes.unknownErrorCode.rawValue), userName: userName, endPointName: endPointName)
                            }
                            else if checkReponseData.result.code != ServerResponseCodes.successCode.rawValue {
                                // SEND DEVICE LOGS TO KAHUNA SERVER
                                self.sendDeviceLogsToServer(request: requestString, with: responseString, urlPath: path, erroCode: Double(checkReponseData.result.code), userName: userName, endPointName: endPointName)
                                /*if checkReponseData.result.code == ServerResponseCodes.sessionExpireErrorCode.rawValue {
                                    let appDelegate = UIApplication.shared.delegate as? AppDelegate
                                    appDelegate?.logoutUser()
                                }*/
                            }
                            var code = 0
                            if checkReponseData.result != nil {
                                code = checkReponseData.result.code
                            }
                            // SEND TIME STAMP VALUES TO KAHUNA SERVER
                            if jsonObject is NSDictionary {
                                let jsonObjectDict = jsonObject as? NSDictionary
                                var responseStatus = "Success"
                                if code != ServerResponseCodes.successCode.rawValue {
                                    responseStatus = "Failure"
                                }
                                print("isdictionary")
                                var requestInTime = ""
                                var requestOutTime = ""
                                if let time = jsonObjectDict?["requestInTime"] {
                                    requestInTime = String(format: "%@", (time as? String)!) // time as! String
                                }
                                if let otime = jsonObjectDict?["requestOutTime"] {
                                    requestOutTime = String(format: "%@", (otime as? String)!)
                                }
                                self.sendTimeStampLogsToServer(path, responseStatus: responseStatus, mobileReqStart: requestStartTime, mobileResponseReceive: responseReceiveTime, mobileServiceParse: responseParseTime, serverRequestReceive: requestInTime, serverResponseStart: requestOutTime)
                            }
                            self.handleResponse(jsonResponse: jsonObject as AnyObject, forPath: path)
                        }
                        catch let JSONError as NSError {
                            self.handleError(error: JSONError, forPath: path)
                        }
                    }
                }
                break
            }
        })
    }
    
    // MARK: - HANDLE RESPONSE
    /**
     Calls httpRequest class delegate with parameters URLPath and jsonResponse Object.
     - parameter path:  The URL string.
     - parameter response: The JSON Response Object.
     */
    public func handleResponse(jsonResponse response:AnyObject, forPath path:String) {
        self.delegate?.httpRequest(requestHandler: self, requestCompletedWithResponseJsonObject: response, forPath: path)
    }
    // MARK: - HANDLE ERROR
    /**
     Calls httpRequest class delegate with parameters Error and URLPath.
     - parameter URLString:  The URL string.
     - parameter Error: The failure service error.
     */
    public func handleError(error:Error, forPath path:String) {
        self.delegate?.httpRequest(requestHandler: self, requestFailedWithError: error, forPath: path)
    }
    // MARK: - DEVICE LOGS
    /*
     Calls KALogger Device logs service
     - parameter request:  The request sent to server.
     - parameter response:  The response received from server.
     - parameter urlPath:  The URL string.
     - parameter erroCode:  The Error code.
     - parameter userName:  The username.
     - parameter endPointName:  The endpoint.
    */
    public func sendDeviceLogsToServer(request:String?, with response:String?, urlPath:String, erroCode:Double, userName: String, endPointName: String) {
        print("erroCode\(erroCode)")
        KALogger.sendDeviceLogsToServer(withRequest: request, withResponse: response, urlPath: endPointName, userName: userName, errorCode: NSNumber(value:erroCode))
    }
    // MARK: - TIME STAMP
    /**
     Calls KALogger timeStampLogs service
     - parameter serviceType:  The URL string.
     - parameter responseStatus: The responseStatus Success or Failure.
     - parameter mobileReqStart: The mobile request start time.
     - parameter mobileResponseReceive: The mobile response receive time.
     - parameter mobileServiceParse: The mobile service received response parse time.
     - parameter serverRequestReceive: The Server request In time.
     - parameter serverResponseStart: The Server request out time.
     */
    public func sendTimeStampLogsToServer(_ serviceType: String, responseStatus: String, mobileReqStart: String, mobileResponseReceive: String, mobileServiceParse: String, serverRequestReceive: String, serverResponseStart: String)
    {
        KALogger.sendTimeStampLogsToServer(forServiceType: serviceType, responseStatus: responseStatus, mobileRequestStartTime: mobileReqStart, mobileResponseReceiveTime: mobileResponseReceive, mobileServiceParseTime: mobileServiceParse, serverRequestReceiveTime: serverRequestReceive, serverResponseStartTime: serverResponseStart)
    }
  // MARK: - GET CURRENT DATE
  /**
   Returns current date
  */
    public func getCurrentDate() -> String {
        let date = Date()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        var dateString = dateFormatter.string(from: date)
        dateString = dateString.replacingOccurrences(of: " ", with: "T")
        return dateString
    }
    // MARK: - CANCELS ALL REQUESTS
    /**
     Cancels all request
     */
    public func cancelAllRequests() {
        self.alamofireManager.session.getTasksWithCompletionHandler {
            (dataTasks, uploadTasks, downloadTasks) -> Void in
            
            dataTasks.forEach { $0.cancel() }
            uploadTasks.forEach { $0.cancel() }
            downloadTasks.forEach { $0.cancel() }
        }
    }
}

