Pod::Spec.new do |s|
  s.name             = 'Entrig'
  s.version          = '0.0.1-dev'
  s.summary          = 'Entrig SDK for iOS - No-code Push Notifications for Supabase'
  s.description      = <<-DESC
Entrig SDK provides seamless push notification integration for iOS applications using Supabase.
Features include automatic registration, notification handling, and Supabase auth integration.
                       DESC
  s.homepage         = 'https://entrig.com'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Entrig' => 'team@entrig.com' }
  s.source           = { :git => 'https://github.com/entrig/entrig-ios.git', :tag => s.version.to_s }

  s.ios.deployment_target = '14.0'
  s.swift_version = '5.0'

  s.source_files = 'Sources/Entrig/**/*.swift'

  s.frameworks = 'Foundation', 'UserNotifications', 'UIKit'
end
