
Pod::Spec.new do |s|
  s.name             = 'Mockingbird-Swift'
  s.version          = '2.0.4'
  s.summary          = 'Network Abstraction Layer written in Swift and leveraging URLSession'

  s.description      = <<-DESC
  Network Abstraction Layer written in Swift and leveraging URLSession.
                       DESC

  s.homepage         = 'https://github.com/jandro-es/Mockingbird'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Alejandro Barros Cuetos' => 'jandro@filtercode.com' }
  s.source           = { :git => 'https://github.com/jandro-es/Mockingbird.git', :tag => s.version.to_s }

  s.ios.deployment_target = '10.0'
  s.osx.deployment_target = '10.12'
  s.default_subspec = "Core"
  s.swift_version = '5.0'

  s.subspec "Core" do |ss|
    ss.source_files  = "Sources/Mockingbird/", "Sources/Mockingbird/Middleware/", "Sources/Mockingbird/Extensions/"
    ss.framework  = "Foundation"
  end

  s.subspec "RxSwift" do |ss|
    ss.source_files = "Sources/RxMockingbird/"
    ss.dependency "Mockingbird-Swift/Core"
    ss.dependency "RxSwift", "~> 5.0"
  end

end
