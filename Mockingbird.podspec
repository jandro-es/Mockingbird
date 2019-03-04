
Pod::Spec.new do |s|
  s.name             = 'Mockingbird'
  s.version          = '1.0.0'
  s.summary          = 'Network Abstraction Layer written in Swift and leveraging URLSession'

  s.description      = <<-DESC
  Network Abstraction Layer written in Swift and leveraging URLSession.
                       DESC

  s.homepage         = 'https://github.com/jandro-es/Mockingbird'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Alejandro Barros Cuetos' => 'jandro@filtercode.com' }
  s.source           = { :git => 'https://github.com/jandro-es/Mockingbird.git', :tag => s.version.to_s }

  s.ios.deployment_target = '9.0'

  s.source_files = 'Sources/**/*'
end
