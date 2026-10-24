# Uncomment the next line to define a global platform for your project
platform :osx, '10.15'

target 'Pock' do

  # Comment the next line if you don't want to use dynamic frameworks
  use_frameworks!

  # PockKit — HTTPS so the build does not depend on a GitHub SSH key
  pod 'PockKit', :git => 'https://github.com/pock/pockkit.git'

  # Analytics
  pod 'AppCenter/Analytics'
  pod 'AppCenter/Crashes'

  # Utils
  pod 'Magnet'
  pod 'Zip'

end

# Zip 2.1.2 / TinyConstraints still ship MACOSX_DEPLOYMENT_TARGET 10.9/10.11.
# Xcode 15+ refuses anything below 10.13, so lift every pod to the app floor.
post_install do |installer|
  installer.pods_project.targets.each do |t|
    t.build_configurations.each do |config|
      config.build_settings['MACOSX_DEPLOYMENT_TARGET'] = '10.15'
    end
  end
end
