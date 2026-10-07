Pod::Spec.new do |s|
  s.name                  = 'adjust_ia_sdk_flutter'
  s.version               = '5.8.0'
  s.summary               = 'Adjust Flutter SDK for iOS platform'
  s.description           = <<-DESC
                            Adjust Flutter SDK for iOS platform.
                            DESC
  s.homepage              = 'http://www.adjust.com'
  s.license               = { :file => '../LICENSE' }
  s.author                = { 'Adjust' => 'sdk@adjust.com' }
  s.source                = { :path => '.' }
  s.source_files          = 'adjust_ia_sdk_flutter/Sources/adjust_ia_sdk_flutter/**/*.swift'
  s.ios.deployment_target = '13.0'

  s.dependency 'Flutter'
  s.dependency 'Adjust', '5.8.0'
end
