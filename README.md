# Sequel-vault

Use [fernet](https://github.com/fernet/fernet-rb) to encrypt columns values in your Sequel database

## Usage

```ruby
class AWSCreds < Sequel::Model
  # attrs :access_key_id, ::access_key_id_digest, :secret_access_key, :secret_access_key_digest :region, :name
  plugin :vault
  vault_attributes ['Fernet key','...'], :access_key_id, :secret_access_key
end
```
