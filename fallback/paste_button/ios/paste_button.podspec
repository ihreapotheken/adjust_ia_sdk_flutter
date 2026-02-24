Pod::Spec.new do |s|
  s.name                  = 'paste_button'
  s.version               = '0.0.1'
  s.summary               = 'Flutter plugin wrapping UIPasteControl for iOS 16+'
  s.description           = <<-DESC
                            A Flutter platform view plugin that embeds
                            UIPasteControl, providing system-mediated paste
                            without permission prompts.
                            DESC
  s.homepage              = 'https://github.com/adjust/flutter_sdk'
  s.license               = { :file => '../LICENSE' }
  s.author                = { 'Adjust' => 'sdk@adjust.com' }
  s.source                = { :path => '.' }
  s.source_files          = 'Classes/**/*.swift'
  s.ios.deployment_target  = '12.0'

  s.dependency 'Flutter'
end
