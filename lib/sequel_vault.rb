require "fernet"
require "sequel"

module Sequel
  module Plugins
    module Vault
      class InvalidCiphertext < Exception; end

      def self.apply(model, keys = [], *attrs)
        model.instance_eval do
          @vault_attrs = attrs
          @vault_keys = keys
        end
      end

      def self.configure(model, keys = [], *attrs)
        model.vault_attributes(keys, *attrs) unless attrs.empty?
      end

      module ClassMethods
        attr_reader :vault_attrs
        attr_reader :vault_keys
        attr_reader :vault_module

        Plugins.inherited_instance_variables(self, :@vault_attrs => :dup, :@vault_keys => :dup)

        def vault_attributes(keys, *attrs)
          raise(Error, 'must provide both keys name and attrs when setting up vault') unless keys && attrs
          @vault_keys = keys
          @vault_attrs = attrs

          self.class.instance_eval do
            attrs.each do |attr|
              define_method("#{attr}_lookup") do |plain|
                digests = keys.map { |key| Sequel.blob(digest(key, plain)) }
                where("#{attr}_digest": digests).first
              end
            end
          end
        end

        def digest(keys, plain)
          OpenSSL::HMAC.digest(OpenSSL::Digest.new('sha512'), Array(keys).last, plain)
        end

        def encrypt(keys, plain)
          ::Fernet.generate(keys.last, plain)
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

      module DatasetMethods
      end

      module InstanceMethods
        def []=(attr, plain)
          if model.vault_attrs.include?(attr) && !plain.nil?
            send("#{attr}_digest=", self.class.digest(model.vault_keys, plain))
            value = self.class.encrypt(model.vault_keys, plain)
          end
          super(attr, value || plain)
        end

        def [](attr)
          if model.vault_attrs.include?(attr)
            cypher = super(attr)
            self.class.decrypt(model.vault_keys, cypher) unless cypher.nil?
          else
            super(attr)
          end
        end
      end
    end
  end
end
