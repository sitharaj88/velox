Pod::Spec.new do |s|
  s.name             = 'velox_biometrics'
  s.version          = '0.1.0'
  s.summary          = 'Biometric authentication for Flutter.'
  s.description      = <<-DESC
Biometric authentication for Flutter with fingerprint, face recognition,
and PIN fallback support.
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
