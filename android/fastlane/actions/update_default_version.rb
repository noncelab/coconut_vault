module Fastlane
  module Actions
    module SharedValues
    end

    class UpdateDefaultVersionAction < Action
      def self.run(params)
        require 'yaml'
        pubspec = YAML.load_file('../pubspec.yaml')
        from = params[:from]

        # 처리 버전
        puts "\n[VERSION]"
        puts "#{from}: #{pubspec[from]}"

        # DEFAULT 버전 변경하여 저장
        puts "\n[DEFAULT VERSION]"
        lines = File.readlines("../pubspec.yaml")
        for i in 0..lines.length()
            if lines[i].to_s.include? "version:"
              lines[i] = "version: #{pubspec[from]}"
              puts lines[i]
            end
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
          [
           FastlaneCore::ConfigItem.new(
                   key: :from,
                   description: "from version key's version to default version in pubspec",
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
