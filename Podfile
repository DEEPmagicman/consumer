# Uncomment the next line to define a global platform for your project
# platform :ios, '9.0'

target 'SpeakEasy-Consumer' do
  # Comment the next line if you don't want to use dynamic frameworks
  use_frameworks!

  # Pods for SpeakEasy
  pod 'Hero'
  pod 'UITextView+Placeholder'
  pod 'DropDown'
  pod 'SCPageControl'
  pod "GSImageViewerController"
  pod "FlagPhoneNumber"
  pod 'OTPFieldView'
  pod 'SVProgressHUD'
  pod 'GoogleSignIn'
  pod 'JWTDecode'
  pod 'NBBottomSheet', '~> 1.2'
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
#      config.build_settings["EXCLUDED_ARCHS[sdk=iphonesimulator*]"] = "arm64"
      config.build_settings['ENABLE_BITCODE'] = 'YES'
      config.build_settings['CODE_SIGNING_ALLOWED'] = 'NO'
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '14.0'
    end
  end
end
