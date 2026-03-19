Pod::Spec.new do |s|
  s.name             = 'archive_extract'
  s.version          = '0.1.0'
  s.summary          = 'Native 7z extraction using system libarchive.'
  s.homepage         = 'https://github.com/moonfin'
  s.license          = { :type => 'MIT' }
  s.author           = 'Moonfin'
  s.source           = { :path => '.' }
  s.source_files     = [
    'Classes/ArchiveExtractPlugin.swift',
    '../shared/**/*.{h,c,swift}'
  ]
  s.dependency 'FlutterMacOS'
  s.platform         = :osx, '10.14'
  s.swift_version    = '5.0'
  s.library          = 'archive'
  s.pod_target_xcconfig = {
    'DEFINES_MODULE' => 'YES',
    'HEADER_SEARCH_PATHS' => '$(SDKROOT)/usr/include',
  }
end
