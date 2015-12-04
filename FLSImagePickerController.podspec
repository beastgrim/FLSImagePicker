Pod::Spec.new do |s|
  s.name         = "FLSImagePickerController"
  s.version      = "0.0.2"
  s.summary      = "A Multiple Selection Image Picker from photo library."
  s.homepage     = "https://github.com/beastgrim/FLSImagePicker"
  s.license      = "MIT"

  s.author             = { "Bogomolov Evgeny" => "http://vk.com/dj_vize" }
  s.social_media_url   = "http://vk.com/dj_vize"
  s.platform     = :ios, "8.0"

  s.source       = { :git => "https://github.com/beastgrim/FLSImagePicker.git", :tag => "0.0.2" }

  s.source_files  = "FLSImagePicker_Demo/FLSImagePickerController/*.{h,m}"
  s.exclude_files = "Classes/Exclude"
  s.ios.frameworks = "Foundation", "UIKit", "AssetsLibrary", "CoreLocation"
  s.requires_arc = true
end