Pod::Spec.new do |s|
  s.name             = 'EntrigSDK'
  s.version          = '1.0.0'
  s.summary          = 'Entrig SDK for iOS - No-code Push Notifications for Supabase'
  s.description      = <<-DESC
Entrig SDK provides seamless push notification integration for iOS applications using Supabase.
                       DESC
  s.homepage         = 'https://entrig.com'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Entrig' => 'team@entrig.com' }
  s.source           = { :git => 'https://github.com/entrig/entrig-ios.git', :tag => s.version.to_s }

  s.ios.deployment_target = '14.0'
  s.swift_version = '5.0'

  s.source_files = 'Sources/Entrig/**/*.swift'

  # Keep module name as 'Entrig' so imports don't change
  s.module_name = 'EntrigSDK'

  s.frameworks = 'Foundation', 'UserNotifications', 'UIKit'
end
