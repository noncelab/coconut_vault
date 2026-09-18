# frozen_string_literal: true

require "open3"

module AndroidSigningHelper
  UI = FastlaneCore::UI

  # ANDROID_SIGNING_*_PASSWORD env가 없으면 프롬프트로 받아 검증 후 설정한다.
  # 반환값: 이번에 프롬프트로 설정했는지 여부 (ensure에서 env 정리 판단용)
  def self.ensure_password!(root_dir:, flavor:)
    store_pw = ENV["ANDROID_SIGNING_STORE_PASSWORD"].to_s
    key_pw = ENV["ANDROID_SIGNING_KEY_PASSWORD"].to_s
    return false unless store_pw.empty? || key_pw.empty?

    password = UI.password(prompt: "Keystore/key password (#{flavor}): ").to_s
    UI.user_error!("Keystore/key password cannot be empty.") if password.empty?
    validate_password!(root_dir: root_dir, flavor: flavor, password: password)
    ENV["ANDROID_SIGNING_STORE_PASSWORD"] = password
    ENV["ANDROID_SIGNING_KEY_PASSWORD"] = password
    true
  end

  # android/key_<flavor>.properties의 keyAlias/storeFile 기준으로 keytool 검증
  def self.validate_password!(root_dir:, flavor:, password:)
    properties_file = File.join(root_dir, "android", "key_#{flavor}.properties")
    UI.user_error!("Keystore properties file not found: #{properties_file}") unless File.file?(properties_file)

    key_alias = signing_property(properties_file, "keyAlias")
    store_file = signing_property(properties_file, "storeFile")
    if key_alias.to_s.empty? || store_file.to_s.empty?
      UI.user_error!("keyAlias and storeFile are required in #{properties_file}")
    end

    resolved_store_file = File.expand_path(store_file, File.join(root_dir, "android", "app"))
    UI.user_error!("Keystore file not found: #{resolved_store_file}") unless File.file?(resolved_store_file)

    stdout, stderr, status = Open3.capture3(
      "keytool", "-J-Duser.language=en", "-J-Duser.country=US",
      "-list", "-keystore", resolved_store_file, "-storepass", password
    )
    UI.user_error!("Invalid keystore password for #{flavor}.") unless status.success?
    unless "#{stdout}\n#{stderr}".match?(/^Keystore type: PKCS12\s*$/i)
      UI.user_error!("The #{flavor} keystore must use the PKCS12 format.")
    end

    _, _, alias_status = Open3.capture3(
      "keytool", "-J-Duser.language=en", "-J-Duser.country=US",
      "-list", "-keystore", resolved_store_file, "-alias", key_alias, "-storepass", password
    )
    UI.user_error!("Key alias #{key_alias} was not found for #{flavor}.") unless alias_status.success?
  rescue Errno::ENOENT
    UI.user_error!("keytool was not found. Install a JDK and try again.")
  end

  def self.signing_property(properties_file, key)
    line = File.readlines(properties_file, chomp: true).find do |candidate|
      candidate.match?(/^\s*#{Regexp.escape(key)}\s*=/)
    end
    line&.split("=", 2)&.last&.strip
  end
end
