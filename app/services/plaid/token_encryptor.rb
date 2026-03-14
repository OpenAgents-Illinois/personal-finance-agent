module Plaid
  module TokenEncryptor
    module_function

    def encrypt(value)
      encryptor.encrypt_and_sign(value)
    end

    def decrypt(value)
      encryptor.decrypt_and_verify(value)
    end

    def encryptor
      key = ActiveSupport::KeyGenerator.new(Rails.application.secret_key_base)
                                       .generate_key("plaid_access_token", 32)
      ActiveSupport::MessageEncryptor.new(key)
    end
  end
end
