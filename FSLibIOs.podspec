Pod::Spec.new do |spec|

  spec.name         = "FSLibIOs"
  spec.version      = "2.2.1"
  spec.summary      = "An iOS library to control the feelSpace naviBelt from your application."

  spec.description  = <<-DESC
Connect and control a feelSpace naviBelt (a tactile belt with vibration motors) from your application. The FSLib use Bluetooth Low Energy to communicate with the naviBelt. The FSLib can be used in multiple domains to provide a tactile feedback, for instance in navigation applications, VR, simulation, research experiments, outdoor and video-games, attention feedback. 
                   DESC

  spec.homepage     = "https://github.com/feelSpace/FSLib-iOS"

  spec.license      = { :type => "apache-2.0", :file => "LICENSE" }

  spec.author             = { "D. Meignan" => "dev@feelspace.de" }

  spec.platform     = :ios, "12.0"

  spec.source       = { :git => "https://github.com/feelSpace/FSLib-iOS.git", :tag => spec.version }

  spec.source_files  = "FSLibIOs/FSLibIOs", "FSLibIOs/FSLibIOs/**/*.{swift,h}"
  spec.exclude_files = "FSLibIOs/FSLibIOsTests", "FSLibIOs/FSLibIOsTests/**/*.{swift,h}"

  spec.swift_version = "5.0"

end
