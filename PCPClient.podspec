Pod::Spec.new do |s|
  s.name             = 'PCPClient'
  s.version          = '1.0.0'
  s.summary          = 'PAYONE Commerce Platform Client iOS SDK for the PAYONE Commerce Platform.'
  s.description      = 'This SDK provides everything a client needs to easily complete payments using Credit or Debit Card, PAYONE Buy Now Pay Later (BNPL) and Apple Pay.'
  s.homepage         = 'https://github.com/PAYONE-GmbH/PCP-client-iOS-SDK'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'PAYONE GmbH' => 'integrations@payone.com' }
  s.source           = { :git => 'https://github.com/PAYONE-GmbH/PCP-client-iOS-SDK.git', :tag => s.version }
  s.swift_version    = '5.10'
  s.platform     = :ios, '15.0'
  s.resource_bundles = {'PCPClient' => ['PrivacyInfo.xcprivacy']}

  s.subspec 'PCPClient' do |pcpclient|
    pcpclient.source_files = 'Sources/PCPClient/**/*'
  end

  s.subspec 'PCPClientBridge' do |pcpclientbridge|
    pcpclientbridge.source_files = 'Sources/PCPClientBridge/**/*'
    pcpclientbridge.dependency 'PCPClient/PCPClient'
  end
end