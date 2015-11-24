Pod::Spec.new do |s|
    s.name = 'FLSImagePickerController'
    s.version = ‘0.0.1’
    s.summary = 'A Multiple Selection Image Picker from photo library.’
    s.homepage = 'https://github.com/beastgrim/FLSImagePicker.git'
    s.license = {
      :type => 'MIT',
      :file => 'README.md'
    }
    s.author = {‘Bogomolov Evgeny’ => 'http://vk.com/dj_vize'}
    s.source = {:git => 'https://github.com/beastgrim/FLSImagePicker.git',
    			:tag => ‘0.0.1’
    		   }
    s.platform = :ios, ‘8.0’
    s.resources = 'Classes/**/*.{xib,png}'
    s.source_files = 'FLSImagePicker_Demo/FLSImagePicker/*.{h,m}'
    s.framework = 'Foundation', 'UIKit', 'AssetsLibrary', 'CoreLocation'
    s.requires_arc = true
end
