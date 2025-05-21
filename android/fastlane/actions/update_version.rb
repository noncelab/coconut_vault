module Fastlane
  module Actions
    module SharedValues
    end

    class UpdateVersionAction < Action
      def self.if_version_then_change(pubspec, lines, i, key)
        if lines[i].to_s.include? "#{key}:"
          splits = pubspec[key].split('+')
          new_version = "#{splits[0]}+#{(splits[1].to_i + 1).to_s}" # build + 1
          lines[i] = "#{key}: #{new_version}"
          puts lines[i]
        end
      end
      
      def self.run(params)
        require 'yaml'
        pubspec = YAML.load_file('../pubspec.yaml')

        # 초기 버전
#         puts "aos_mainnet: #{pubspec['aos_mainnet']}"
#         puts "ios_mainnet: #{pubspec['ios_mainnet']}"
        puts "aos_regtest: #{pubspec['aos_regtest']}"
        puts "ios_regtest: #{pubspec['ios_regtest']}"
        puts "\n[UPDATED VERSION]"

        # 버전 변경하여 저장
        lines = File.readlines("../pubspec.yaml")
        for i in 0..lines.length()
#           if_version_then_change(pubspec, lines, i, "aos_mainnet")
#           if_version_then_change(pubspec, lines, i, "ios_mainnet")
          if_version_then_change(pubspec, lines, i, "aos_regtest")
          if_version_then_change(pubspec, lines, i, "ios_regtest")

           # for android build
          if_version_then_change(pubspec, lines, i, "version")
        end

        File.open("../pubspec.yaml", "w+") do |f|
          f.puts(lines)
        end
      end

      def self.description
        'pubspec 파일의 버전 정보를 업데이트 합니다. '
      end

      def self.details
      end

      def self.available_options
      end

      def self.output
      end

      def self.return_value
      end

      def self.authors
        ['Noncelab']
      end

      def self.is_supported?(platform)
          true
      end
    end
  end
end
