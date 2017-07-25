#
# Be sure to run `pod lib lint SlideMenuSwift.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'SlideMenuSwift'
  s.version          = '0.1.10'
  s.summary          = 'SlideMenu is a Swift framework for hamburger menu.'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
SlideMenu is a Swift framework for hamburger menu.
Based on AMSlideMenu with some improvements.
                       DESC
  s.requires_arc = true
  s.homepage         = 'https://github.com/RupeQ/SlideMenuSwift'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'RupeQ' => 'rupeqdj@gmail.com' }
  s.source           = { :git => 'https://github.com/RupeQ/SlideMenuSwift.git', :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  s.ios.deployment_target = '8.0'

  s.source_files = 'SlideMenuSwift/Classes/**/*'
  s.pod_target_xcconfig =  {
    'SWIFT_VERSION' => '3.0',
  }

  # s.resource_bundles = {
  #   'SlideMenuSwift' => ['SlideMenuSwift/Assets/*.png']
  # }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'UIKit'
  # s.dependency 'AFNetworking', '~> 2.3'
end
