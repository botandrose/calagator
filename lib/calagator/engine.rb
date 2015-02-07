module Calagator
  class Engine < ::Rails::Engine
    isolate_namespace Calagator

    config.before_initialize do
      require 'secrets_reader'
      ::SECRETS = SecretsReader.read
    end
  end
end
