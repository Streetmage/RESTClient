Pod::Spec.new do |s|

  s.name         = "RESTClient-iOS"
  s.version      = "0.1.0"
  s.summary      = "RESTClient is a lightweight wrapper for Alamofire requests that works with JSON responses"
  s.homepage     = "https://github.com/Streetmage/RESTClient"
  s.license      = "MIT"

  s.author = "Evgeny Kubrakov"

  s.ios.deployment_target  = '10.0'

  s.source       = { :git => "https://github.com/Streetmage/RESTClient.git", :tag => "0.1.0" }

  s.source_files  = "RESTClient/*.swift"

  s.requires_arc = true

 s.dependency 'Alamofire'

end
