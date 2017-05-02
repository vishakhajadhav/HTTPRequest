Pod::Spec.new do |s|

  s.name         = "HTTPRequest"
  s.version      = "1.0.13"
  s.summary      = "Handles Service request"
  s.description  = "Handles Server request response"
  s.homepage     = "https://github.com/"
  s.license      = "MIT"
  s.author             = "Kahuna"
  s.platform     = :ios, "8.0"
  s.preserve_path = 'HTTPRequest/LogCamp.modulemap'
  s.source       = { :git => "https://github.com/vishakhajadhav/HTTPRequest.git", :tag => "1.0.13" }
  s.source_files  = "HTTPRequest", "HTTPRequest/**/*.{h,m,swift}"
  s.dependency 'Alamofire' 
  s.public_header_files = "LogCamp/KALogger/*.h"
  s.pod_target_xcconfig = {
    'OTHER_LDFLAGS' => '$(inherited) -undefined dynamic_lookup'
}

s.preserve_path = 'module/module.modulemap'
s.module_map = 'module/module.modulemap'

s.pod_target_xcconfig = { 'HEADER_SEARCH_PATHS' => $(PODS_ROOT)/mypod/module }
s.xcconfig = { 'HEADER_SEARCH_PATHS' => '$(SDKROOT)/usr/include/libxml2 $(PODS_ROOT)/mypod/module }

end
