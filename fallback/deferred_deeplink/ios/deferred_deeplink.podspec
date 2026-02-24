Pod::Spec.new do |s|
  s.name                  = 'deferred_deeplink'
  s.version               = '0.0.1'
  s.summary               = 'Flutter plugin for resolving deferred deep links via device fingerprinting'
  s.description           = <<-DESC
                            A Flutter plugin that collects native iOS device
                            fingerprint data and sends it to a backend endpoint
                            to resolve deferred deep links.
                            DESC
  s.homepage              = 'https://github.com/adjust/flutter_sdk'
  s.license               = { :file => '../LICENSE' }
  s.author                = { 'Adjust' => 'sdk@adjust.com' }
  s.source                = { :path => '.' }
  s.source_files          = 'Classes/**/*.swift'
  s.ios.deployment_target  = '12.0'

  s.dependency 'Flutter'

  s.frameworks            = 'CoreTelephony'
end
