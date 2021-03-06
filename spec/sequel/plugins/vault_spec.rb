require 'spec_helper'

describe Sequel::Plugins::Vault do
  let(:db) { Sequel.mock(autoid: 1) }
  let(:klass) do
    Class.new(Sequel::Model(db[:vm])) do
      set_primary_key :id
      unrestrict_primary_key
      set_columns(%i[id secret secret_digest key_id])

      plugin :vault
    end
  end
  let(:dataset) { klass.dataset }
  let(:model) { klass.new }
  let(:keys) do
    ['fih3l0Z9e4NBpy5KIj+rmXVexY5O9LspzuqCFyqavjg=',
     'woRXJWevRaxZLxgoiEQtCDPBSf9TNg57bki0RUK1U48=']
  end
  let(:secret) { 'Attack at once.' }
  let(:cypher) { klass.encrypt(keys, secret) }
  let(:digest) { OpenSSL::HMAC.digest('sha512', keys.last, secret) }

  it 'encrypts vault attributes' do
    klass.vault_attributes(keys, :secret)
    model.secret = secret
    expect(model.values[:secret]).not_to eq(secret)
    expect(model.secret).to eq(secret)
    expect(model.key_id).to eq(2)
  end

  it 'allows nil value' do
    klass.vault_attributes(keys, :secret)
    model.secret = nil
    expect(model.values[:secret]).to be_nil
    expect(model.secret).to be_nil
    expect(model.key_id).to be_nil
  end

  it 'writes a digest of the value' do
    klass.vault_attributes(keys, :secret)
    model.secret = secret
    expect(model.values[:secret_digest]).not_to eq(secret)
    expect(model.secret_digest).to eq(digest)
    expect(model.key_id).to eq(2)
  end

  it 'provides a digest lookup' do
    klass.dataset = dataset.with_fetch([{ id: 1, secret: cypher, secret_digest: digest }])
    klass.vault_attributes(keys, :secret)
    lookup = klass.secret_lookup('secret')
    expect(lookup.secret).to eq(secret)
  end
end
