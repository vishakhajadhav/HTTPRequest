# HTTPRequest
![HTTPRequest](http://www.kahuna-mobihub.com/templates/ja_puresite/images/logo-trans.png)

HTTPRequest handles GET, POST and Multipart webservice call using alamofire framework and it is written in swift

## Installation
### CocoaPods

[CocoaPods](http://cocoapods.org) is a dependency manager for Cocoa projects. 

1] Add GitHub repository link in your pod file
```ruby
pod 'LogCamp', :git => 'https://github.com/PrasadPotale/KahunaLogCamp.git', :tag => '3.2.5' 
pod 'HTTPRequest', :git => 'https://github.com/vishakhajadhav/HTTPRequest.git', :tag => '1.0.4'
```
2] Execute 
```swift
pod install
``` 
on terminal with your project path

3] Add PLCrashReporter-DynamicFramework and LogCamp framework to build-phases
4] In target build settings add 
```swift 
"$PODS_CONFIGURATION_BUILD_DIR/PLCrashReporter-DynamicFramework”, “$(PROJECT_DIR)/LogCamp"
```
5] In target build settings for other linker flag add this 
```swift 
"-undefined dynamic_lookup"
```

### Implementation
##For GET Service
```swift
E.g: let httpRequestObj = HTTPRequest.sharedInstance
httpRequestObj.sendGetRequestAtPath("server url path", withParameters: requestParameters as?[String : AnyObject], timeoutInterval: 60, userName: "username", endpointName: "url endpoint")
```
##For POST Service
```swift
E.g: let httpRequestObj = HTTPRequest.sharedInstance
httpRequestObj.sendGetRequestAtPath("server url path", withParameters: requestParameters as?[String : AnyObject], timeoutInterval: 60, userName: "username", endpointName: "url endpoint")
sendRequestAtPath("server url", withParameters: requestParameters as?[String : AnyObject], timeoutInterval: 60, andToken: "tokenString", userName: "name", endpointName: "endpoint")
```

##For Multipart Service
```swift
let httpRequestObj = HTTPRequest.sharedInstance
 httpRequestObj.sendMultipartRequestAtPath("server url path", withImagePaths: [imagePathArray], andParameters: requestParameters as?[String : AnyObject], timeoutInterval: 60, userToken: "tokenString", uploadImageKeyName: "keyname", imageUploadJSONName: "JSON_name", userName: "username", endPointName: "endpoint")
```
