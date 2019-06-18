Pod::Spec.new do |s|
    s.name         = 'HGImagePickerController'
    s.version      = '0.0.1'
    s.summary      = '这是个测试pod' 
    s.homepage     = "https://github.com/pengweijunPanda/PPTestPhotoKit.git"
    s.license      = "MIT"
    s.authors      = { 'panda' => '51365338@qq.com'}
    s.platform     = :ios,'7.0'
    s.source       = { :git => "https://github.com/pengweijunPanda/PPTestPhotoKit.git", :tag => s.version }
    s.source_files = "HGImagePickerController/Classes/*.{h,m}" 
    s.requires_arc = true 
   
end
