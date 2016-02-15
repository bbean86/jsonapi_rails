$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'jsonapi_rails'
require 'active_support'
require 'active_support/core_ext'
Bundler.require :default, :development, :test
require 'active_record'
require 'yaml'
database_config = YAML.load_file(File.expand_path("../config/database.yml", __FILE__))
ActiveRecord::Base.establish_connection(database_config['test'])

ActiveRecord::Schema.define do
  create_table :people, force: true do |t|
    t.string     :uuid
    t.string     :name
    t.timestamps null: false
  end

  create_table :articles, force: true do |t|
    t.string :uuid
    t.belongs_to :person
    t.timestamps null: false
  end
end

module Identifiers
  def self.included(model)
    model.after_initialize do
      self.uuid ||= SecureRandom.uuid
    end
  end
end

class Person < ActiveRecord::Base
  include Identifiers

  has_many :articles
end

class Article < ActiveRecord::Base
  include Identifiers

  belongs_to :person
end

class PersonResource < JsonApi::Resource
  id_field :uuid
  attribute :name
  attribute :overridden_name

  has_many :articles

  def overridden_name
    object.name + '!!'
  end
end

class AlternatePersonResource < JsonApi::Resource
  id_field :uuid
  attribute :name
end

class ArticleResource < JsonApi::Resource
  id_field :uuid

  has_one :person
end
