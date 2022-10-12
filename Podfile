# Uncomment the next line to define a global platform for your project
# platform :ios, '9.0'

target 'SpeakEasy-Consumer' do
  # Comment the next line if you don't want to use dynamic frameworks
  use_frameworks!

  # Pods for SpeakEasy
  pod 'Alamofire', '4.9.1'
  pod 'SwiftyJSON'
  pod 'RealmSwift'
  pod 'ObjectMapper'
  pod 'ObjectMapper+Realm'
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
end
post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings["EXCLUDED_ARCHS[sdk=iphonesimulator*]"] = "arm64 i386"
    end
  end
end
