# Uncomment the next line to define a global platform for your project
# platform :ios, '9.0'

target 'SpeakEasy-Consumer' do
  # Comment the next line if you don't want to use dynamic frameworks
  use_frameworks!

  # Pods for SpeakEasy
  pod 'Alamofire', '4.9.1'
  pod 'SDWebImage'
  pod 'Hero'
  pod 'NVActivityIndicatorView', '4.7.0'
  pod 'PhoneNumberKit'
  pod 'DZNEmptyDataSet'
  pod 'UITextView+Placeholder'
  pod 'FSCalendar'
  pod 'IQKeyboardManagerSwift'
  pod 'DropDown'
  pod 'Charts'
  pod 'SCPageControl'
  pod 'GoogleMaps'
  pod "GSImageViewerController"
  pod "FlagPhoneNumber"
  pod 'OTPFieldView'
  pod 'SVProgressHUD'
  pod 'GoogleSignIn'
  pod 'SwiftInstagram', '~> 1.1.2'
  pod 'JWTDecode'
  pod 'StripeApplePay'
  pod 'StripePaymentSheet'
  pod 'ReachabilitySwift', '~> 3'
  pod 'Socket.IO-Client-Swift'
  pod 'NBBottomSheet', '~> 1.2'
  pod 'Firebase/RemoteConfig'
end

target 'SpeakEasyClip' do
  # Comment the next line if you don't want to use dynamic frameworks
  use_frameworks!

  # Pods for SpeakEasyClip
  pod "FlagPhoneNumber"
  pod 'IQKeyboardManagerSwift'
  pod 'DropDown'
  pod 'StripeApplePay'
  pod 'ReachabilitySwift', '~> 3'
  pod 'Socket.IO-Client-Swift'
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['CODE_SIGNING_ALLOWED'] = 'NO'
#      config.build_settings["EXCLUDED_ARCHS[sdk=iphonesimulator*]"] = "arm64 i386"
    end
  end
end
