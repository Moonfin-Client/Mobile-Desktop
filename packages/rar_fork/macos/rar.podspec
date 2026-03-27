#
# macos/rar.podspec
#
# CocoaPods specification for the RAR plugin on macOS.
# Uses UnrarKit for RAR format support via method channels.
#
Pod::Spec.new do |s|
  s.name             = 'rar'
  s.version          = '0.2.1'
  s.summary          = 'Flutter plugin for handling RAR files on macOS.'
  s.description      = <<-DESC
A Flutter plugin for extracting and listing RAR archive contents on macOS.
Uses UnrarKit for RAR format support.
                       DESC
  s.homepage         = 'https://github.com/lkrjangid1/rar'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Lokesh Jangid' => 'lkrjangid@example.com' }

  s.source           = { :path => '.' }
  s.source_files     = 'Classes/**/*'

  s.dependency 'FlutterMacOS'
  s.dependency 'UnrarKit', '~> 2.9'

  s.platform = :osx, '10.15'
  s.pod_target_xcconfig = {
    'DEFINES_MODULE' => 'YES',
  }
  s.swift_version = '5.0'
end
