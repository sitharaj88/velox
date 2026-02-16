Pod::Spec.new do |s|
  s.name             = 'velox_permissions'
  s.version          = '0.1.0'
  s.summary          = 'Cross-platform permission handling for Flutter.'
  s.description      = <<-DESC
Cross-platform permission handling for Flutter with a unified API
for requesting, checking, and managing app permissions.
                       DESC
  s.homepage         = 'https://github.com/velox-flutter/velox'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Velox' => 'info@velox.dev' }
  s.source           = { :path => '.' }
  s.source_files     = 'Classes/**/*'
  s.dependency 'Flutter'
  s.platform         = :ios, '12.0'
  s.swift_version    = '5.0'

  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES' }
end
