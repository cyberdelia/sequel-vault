# Sequel-vault

Use [fernet](https://github.com/fernet/fernet-rb) to encrypt columns values in your Sequel database.

## Installation

Install it directly using gem:

```
gem install sequel_vault
```

Or adding it to your ``Gemfile``:

```
gem "sequel_vault"
```

## Usage

## Configure

A straightforward example, passing keys and columns that will be encrypted
transparently:

```ruby
class Credential < Sequel::Model
  plugin :vault, ['9cLL4qVO+bkEqGQtcvQX4Cz4uJ1ni9Nb83ipU/9klsw='], :token
end
```

Along with a typical migration for this setup:

```ruby
Sequel.migration do
  change do
    alter_table(:credentials) do
      add_column(:token, :bytea)
      add_column(:token_digest, :bytea)
      add_column(:key_id, :smallint)
    end
  end
end
```

### Keys

Vault use [fernet](https://github.com/fernet/fernet-rb) behind the scene, the
keys should be 32 bytes of random data, base64-encoded.

To generate one you can use:

```console
$ dd if=/dev/urandom bs=32 count=1 2>/dev/null | openssl base64
```

You can specify more than one key to be used. The last keys of the array will
be used as the default for encryption.

### Keys migration

If a ``key_id`` column is present, vault will set its value to the length of
the keys array. You can check if a key is still in use using:

```ruby
Credential.where(key_id: 1).empty?
```  

You should avoid removing a key when using ``key_id``, unless you proceed to
migrate its value.

Here is a migration example to add a ``key_id`` column:

```ruby
Sequel.migration do
  change do
    alter_table(:credentials) do
      add_column(:key_id, :smallint)
    end
  end
end
```

### Digest lookup

To allow lookup by a know secret, vault allow an optional digest column for each
encrypted attribute, using the ``_digest`` suffix:

```ruby
Sequel.migration do
  change do
    alter_table(:credentials) do
      add_column(:token_digest, :bytea)
    end
  end
end
```

You can then lookup using the provided dataset lookup:

```ruby
Credential.token_lookup('secret')
```

### Unencrypted data

Vault will return plain-text data if none of the keys can successfully decrypt
the stored value, effectively allowing encrypt on write migration.
