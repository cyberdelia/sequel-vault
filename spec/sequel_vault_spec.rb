# -*- encoding: utf-8 -*-
require "spec_helper"

describe Sequel::Plugins::Vault do
  let(:db) { Sequel.mock(autoid: 1) }
  let(:klass) do
    Class.new(Sequel::Model(db[:vm])) do
      set_primary_key :id
      unrestrict_primary_key
      set_columns([:id, :secret, :secret_digest])

      plugin :vault
    end
  end
  let(:dataset) { klass.dataset }
  let(:model) { klass.new }
  let(:keys) do
    ["woRXJWevRaxZLxgoiEQtCDPBSf9TNg57bki0RUK1U48=",
     "fih3l0Z9e4NBpy5KIj+rmXVexY5O9LspzuqCFyqavjg="]
  end
  let(:secret) { "Attack at once." }
  let(:cypher) { klass.encrypt(keys, secret) }
  let(:digest) { OpenSSL::HMAC.digest('sha512', keys.first, secret) }

  it "should encrypt vault attributes" do
    klass.vault_attributes(keys, :secret)
    model.secret = secret
    expect(model.values[:secret]).to_not eq(secret)
    expect(model.secret).to eq(secret)
  end

  it "should allow nil value" do
    klass.vault_attributes(keys, :secret)
    model.secret = nil
    expect(model.values[:secret]).to be_nil
    expect(model.secret).to be_nil
  end

  it "should write a digest of the value" do
    klass.vault_attributes(keys, :secret)
    model.secret = secret
    expect(model.values[:secret_digest]).to_not eq(secret)
    expect(model.secret_digest).to eq(digest)
  end

  it "should provide a digest lookup" do
    dataset._fetch = { id: 1, secret: cypher, secret_digest: digest }
    klass.vault_attributes(keys, :secret)
    lookup = klass.secret_lookup("secret")
    expect(lookup.secret).to eq(secret)
  end
end
