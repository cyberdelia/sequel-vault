require "fernet"

module Sequel
  module Plugins
    module Vault
      class InvalidCiphertext < Exception; end

      def self.configure(model, keys = nil, *attrs)
        model.vault_attributes(keys, *attrs) unless attrs.empty?
      end

      module ClassMethods
        attr_accessor :vault_attributes_module

        def vault_attributes(keys, *attrs)
          include(self.vault_attributes_module ||= Module.new) unless vault_attributes_module
          vault_attributes_module.class_eval do
            attrs.each do |attr|
              define_method(attr) do
                cypher = super()
                decrypt(keys, cypher) unless cypher.nil?
              end

              define_method("#{attr}=") do |plain|
                return if plain.nil?
                cypher = encrypt(keys, plain)
                digest = OpenSSL::HMAC.digest('sha512', keys.first, plain)
                super(cypher)
                send("#{attr}_digest=", digest)
              end
            end
          end
        end
      end

      module InstanceMethods
        private

        def encrypt(keys, plain)
          ::Fernet.generate(keys.first, plain)
        end

        def decrypt(keys, cypher)
          keys.each do |key|
            verifier = ::Fernet.verifier(key, cypher, enforce_ttl: false)
            next unless verifier.valid?
            return verifier.message
          end
          raise InvalidCiphertext, "Could not decrypt field"
        end
      end
    end
  end
end
