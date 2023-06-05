source 'https://cdn.cocoapods.org/'

project 'ClashX.xcodeproj'

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      if ['FlexibleDiff'].include? target.name
        target.build_configurations.each do |config|
          config.build_settings['SWIFT_VERSION'] = '5'
        end
      end
      config.build_settings['MACOSX_DEPLOYMENT_TARGET'] = '10.13'
    end
  end
end

target 'ClashX Meta' do
  inhibit_all_warnings!
  use_modular_headers!
  pod 'Alamofire', '~> 5.0'
  pod 'SwiftyJSON'
  pod 'RxSwift'
  pod 'RxCocoa'
  pod 'CocoaLumberjack/Swift'
  pod 'WebViewJavascriptBridge'
  pod 'Starscream','3.1.1'
  pod "FlexibleDiff"
  pod 'GzipSwift'
  pod 'Yams'
  pod "PromiseKit", "~> 6.8"
end

