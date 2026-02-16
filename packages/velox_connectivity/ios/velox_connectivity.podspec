Pod::Spec.new do |s|
  s.name             = 'velox_connectivity'
  s.version          = '0.1.0'
  s.summary          = 'Real-time network connectivity monitoring for Flutter.'
  s.description      = <<-DESC
Real-time network connectivity monitoring for Flutter with connection type
detection, bandwidth estimation, and reactive status streams.
                       DESC
  s.homepage         = 'https://github.com/velox-flutter/velox'
  s.license          = { :type => 'MIT', :file => '../LICENSE' }
  s.author           = { 'Velox' => 'info@velox.dev' }
  s.source           = { :http => 'https://github.com/velox-flutter/velox' }
  s.source_files     = 'Classes/**/*'
  s.dependency 'Flutter'
  s.platform         = :ios, '12.0'
  s.swift_version    = '5.0'
end
