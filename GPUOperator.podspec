Pod::Spec.new do |spec|
  spec.name             = 'GPUOperator'
  spec.version          = '0.1.0'
  spec.summary          = 'Simple wrapper for using Metal easily.'
  spec.description      = <<-DESC
Simple wrapper for using Metal easily.
Can run graphics shader and parallel computations without boiler plates.
                       DESC

  spec.homepage         = 'https://github.com/horita-yuya/GPUOperator'
  spec.license          = { :type => 'MIT', :file => 'LICENSE' }
  spec.author           = { 'horita-yuya' => 'horitayuya@gmail.com' }
  spec.source           = { :git => 'https://github.com/horita-yuya/GPUOperator.git', :tag => spec.version.to_s }

  spec.ios.deployment_target = '12.0'

  spec.source_files = 'Sources/**/*.{swift,metal}'
  spec.swift_version = '5.0'
end
