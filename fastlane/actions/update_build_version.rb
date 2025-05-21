module Fastlane
  module Actions
    module SharedValues
    end

    class UpdateBuildVersionAction < Action
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
        pubspec = YAML.load_file('pubspec.yaml')
        version_key = params[:version_key]

        # 초기 버전
        puts "\n[INITIAL VERSION]"
        puts "#{version_key}: #{pubspec[version_key]}"

        # 버전 변경하여 저장
        puts "\n[UPDATED VERSION]"
        lines = File.readlines("pubspec.yaml")
        for i in 0..lines.length()
          if_version_then_change(pubspec, lines, i, version_key)
        end

        File.open("pubspec.yaml", "w+") do |f|
          f.puts(lines)
        end
      end

      def self.description
        'pubspec 파일의 버전 정보를 업데이트 합니다. '
      end

      def self.details
      end

      def self.available_options
          [
           FastlaneCore::ConfigItem.new(
                   key: :version_key,
                   description: "version key to update in pubspec",
                   type: String,
                   optional: false
                 )
          ]
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
