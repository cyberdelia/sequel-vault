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

      # @!attribute [r] vault_attrs
      #   @return [Array<Symbol>] array of all attributes to be encrypted
      # @!attribute [r] vault_keys
      #   @return [Array<String>] array of all keys to be used.
      module ClassMethods
        attr_reader :vault_attrs
        attr_reader :vault_keys

        Plugins.inherited_instance_variables(self, :@vault_attrs => :dup, :@vault_keys => :dup)

        # Setup vault with the given keys for the given attributes.
        #
        # @param [Array<String>] keys to be used
        # @param [Array<Symbol>] attributes that will be encrypted
        def vault_attributes(keys, *attributes)
          raise(Error, 'must provide both keys name and attrs when setting up vault') unless keys && attributes
          @vault_keys = keys
          @vault_attrs = attributes

          self.class.instance_eval do
            attributes.each do |attr|
              define_method("#{attr}_lookup") do |plain|
                digests = keys.map { |key| Sequel.blob(digest(key, plain)) }
                where("#{attr}_digest": digests).first
              end
            end
          end
        end

        # Returns the HMAC digest of plain text.
        #
        # @param [Array<String>] keys to be used
        # @param [String] plain text
        # @return [String] HMAC digest of the plain text
        def digest(keys, plain)
          OpenSSL::HMAC.digest(OpenSSL::Digest.new('sha512'), Array(keys).last, plain)
        end

        # Returns the encrypted version of plain text.
        #
        # @param [Array<String>] keys to be used
        # @param [String] plain text
        # @return [String] encrypted version of the plain text
        def encrypt(keys, plain)
          ::Fernet.generate(keys.last, plain)
        end

        # Returns the decryped version of encrypted text.
        #
        # @param [Array<String>] keys to be used
        # @param [String] cypher text
        # @return [String] plain version of the cypher text
        def decrypt(keys, cypher)
          keys.each do |key|
            verifier = ::Fernet.verifier(key, cypher, enforce_ttl: false)
            next unless verifier.valid?
            return verifier.message
          end
          raise InvalidCiphertext, "Could not decrypt field"
        end
      end

      module InstanceMethods
        def []=(attr, plain)
          if model.vault_attrs.include?(attr) && !plain.nil?
            send("#{attr}_digest=", self.class.digest(model.vault_keys, plain))
            value = self.class.encrypt(model.vault_keys, plain)
            super(:key_id, model.vault_keys.length) if model.columns.include?(:key_id)
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
