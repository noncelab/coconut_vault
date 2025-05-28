module Fastlane
  module Actions
    module SharedValues
    end

    class UpdateAppInfoAction < Action
      def self.run(params)
        require 'date'
        date = Time.now.strftime("%Y.%m.%d")
        file = File.open('lib/constants/app_info.dart', 'w')
        file.puts "// ignore_for_file: constant_identifier_names"
        file.puts "\n"
        file.puts "const RELEASE_DATE = '#{date}';"
        file.puts "const COPYRIGHT_TEXT = '© 2025 Nonce Lab. Inc. in S.Korea.\\nLicensed under the MIT License with Commons Clause.';"
        file.close
      end

      def self.description
        'app_info.dart 파일을 수정합니다.'
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
