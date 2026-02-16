Pod::Spec.new do |s|
  s.name             = 'velox_device'
  s.version          = '0.1.0'
  s.summary          = 'Device information plugin for Flutter.'
  s.description      = <<-DESC
Device information plugin for Flutter with platform detection, screen metrics,
battery status, and hardware details.
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
