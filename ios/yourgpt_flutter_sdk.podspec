Pod::Spec.new do |s|
  s.name             = 'yourgpt_flutter_sdk'
  s.version          = '1.1.0'
  s.summary          = 'YourGPT Flutter SDK — native APNs push notification support for iOS.'
  s.description      = 'Provides native APNs token acquisition and notification handling for the YourGPT Flutter SDK.'
  s.homepage         = 'https://yourgpt.ai'
  s.license          = { :type => 'MIT' }
  s.author           = { 'YourGPT' => 'support@yourgpt.ai' }
  s.source           = { :http => 'https://yourgpt.ai' }
  s.source_files     = 'Classes/**/*'
  s.dependency       'Flutter'
  s.platform         = :ios, '13.0'
  s.swift_version    = '5.0'

  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES' }
end
