source 'https://github.com/CocoaPods/Specs.git'
# This line is needed until OGVKit is fully published to CocoaPods
# Remove once packages published:
source 'https://github.com/brion/OGVKit-Specs.git'

platform :ios, '9.0'

inhibit_all_warnings!
use_frameworks!

abstract_target 'BasePods' do
  # pods
	pod 'AFNetworking', '~> 4.0'
	pod 'Mantle', '2.1.0'
	pod 'MWPhotoBrowser', '2.1.0'
	pod 'OGVKit/WebM', '0.5.13'
	pod 'PureLayout', '3.0.2'
	pod 'Texture', '~> 3.0'
	pod 'TUSafariActivity', '1.0.4'
	pod 'YapDatabase', '3.0.2'
	pod 'GTMNSString-HTML', :git => 'https://github.com/siriusdely/GTMNSString-HTML.git'
	pod 'ARChromeActivity', '~> 1.0'

	# targets
  target 'dvach-browser'
  target 'dvach-browserTests'
end

post_install do |installer|
    installer.pods_project.targets.each do |target|
        if target.name == "PINCache" || target.name == "PINRemoteImage"
            puts "Updating #{target.name} OTHER_CFLAGS"
            target.build_configurations.each do |config|
                config.build_settings['OTHER_CFLAGS'] ||= ['$(inherited)']
                config.build_settings['OTHER_CFLAGS'] << '-Xclang -fcompatibility-qualified-id-block-type-checking'
            end
	elsif target.name == "GTMNSString-HTML"
	    puts "Disabling CLANG_ENABLE_OBJC_ARC for #{target.name}"
            target.build_configurations.each do |config|
                config.build_settings['CLANG_ENABLE_OBJC_ARC'] = 'NO'
            end
        end
    end
end