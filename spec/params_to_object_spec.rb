require 'spec_helper'

# Mock object to test non existent relationships
Hahahha = Class.new do
  def self.find_or_initialize_by_uuid(uuid)
    self.new
  end
end

describe JsonApiRails::ParamsToObject do
  it 'finds the object by id' do
    person = Person.create!
    expect(JsonApiRails::ParamsToObject.new({data: { id: person.id.to_s, type: 'people' } }).object).to eq person
  end

  it 'raises an error if type is missing' do
    expect{
      JsonApiRails::ParamsToObject.new({data: {}})
    }.to raise_error "Field `data' is malformed or missing"
  end

  it 'finds the object by uuid' do
    uuid = SecureRandom.uuid
    person = Person.create!(uuid: uuid)
    expect(JsonApiRails::ParamsToObject.new({data: { id: uuid, type: 'people' } }).object).to eq person
  end

  it "initializes a new object if no id is provided" do
    expect(JsonApiRails::ParamsToObject.new({data: {type: 'people' } }).object.id).to be_nil
  end

  it 'initializes a new object if no record is found by the provided uuid' do
    uuid   = SecureRandom.uuid
    params = { data: { id: uuid, type: 'people' } }
    person = JsonApiRails::ParamsToObject.new(params).object
    expect(person.new_record?).to be_truthy
  end

  it 'scopes the object to the provided ActiveRecord::Relation' do
    person  = Person.create! name: 'Ben Solo'
    article = Article.new uuid: SecureRandom.uuid
    person.articles << article
    params          = { data: { id: article.uuid, type: 'articles' } }
    article_wrapper = JsonApiRails::ParamsToObject.new params,
                                                            person.articles
    expect(article_wrapper.object).to eql(article)
  end

  describe 'attributes' do
    it 'updates an attribute' do
      params_object = JsonApiRails::ParamsToObject.new({
        data: {
          type: 'people',
          attributes: {
            name: 'mac'
          }
        }
      })
      expect(params_object.object.name).to eq 'mac'
    end

    it 'swallows assignment of any attribute defined on the Resource class but not the underlying model' do
      expect {
        JsonApiRails::ParamsToObject.new(
          data: {
            type: 'people',
            attributes: {
              overridden_name: 'Ben',
              name: 'Benjamin'
            }
          }
        )
      }.to_not raise_error
    end

    it "raises an error if the object doesn't have the attribute and it is not defined on its Resource" do
      expect{
        JsonApiRails::ParamsToObject.new({
          data: {
            type: 'people',
            attributes: {
              not_an_attribute: 'nope'
            }
          }
        })
      }.to raise_error("`Person' does not have attribute `not_an_attribute'")
    end
  end

  describe 'relationships' do
    it 'sets a one to one relationship' do
      uuid = SecureRandom.uuid
      Person.create!(uuid: uuid)
      params_object = JsonApiRails::ParamsToObject.new({
        data: {
          type: 'articles',
          relationships: {
            person: {
              data: { id: uuid, type: 'people' }
            }
          }
        }
      })
      expect(params_object.object.person).to be_an_instance_of(Person)
    end

    it 'allows setting a to_one relationship to nil' do
      uuid = SecureRandom.uuid
      hooman = Person.create!(uuid: SecureRandom.uuid)
      article = Article.create!(uuid: uuid)
      hooman.articles << article
      hooman.save!

      params_object = JsonApiRails::ParamsToObject.new({
        data: {
          id: uuid,
          type: 'articles',
          relationships: {
            person: {
              data: nil
            }
          }
        }
      })

      expect(params_object.object.person).to be_nil
    end

    it 'allows setting a to_many relationship to an empty array' do
      uuid = SecureRandom.uuid
      person = Person.create!(uuid: uuid)
      person.articles << Article.create!(uuid: SecureRandom.uuid)

      params_object = JsonApiRails::ParamsToObject.new({
        data: {
          id: uuid,
          type: 'people',
          relationships: {
            articles: {
              data: []
            }
          }
        }
      })

      expect(params_object.object.articles).to eq []
    end

    it 'replaces relationships with the relationship array' do
      uuid = SecureRandom.uuid
      person = Person.create!(uuid: uuid)
      person.articles << Article.create!(uuid: SecureRandom.uuid)

      # This one will be "found" so we can assign it to the person
      existing_article_uuid = SecureRandom.uuid
      article = Article.create!(uuid: existing_article_uuid)

      expected_articles = [article]

      params_object = JsonApiRails::ParamsToObject.new({
        data: {
          id: uuid,
          type: 'people',
          relationships: {
            articles: {
              data: [{ id: existing_article_uuid, type: 'articles' }]
            }
          }
        }
      })

      expect(params_object.object.articles).to eq expected_articles
    end

    it "raises an error if the relationship object can't be found" do
      uuid = SecureRandom.uuid
      Person.create!(uuid: uuid)
      expect{
      JsonApiRails::ParamsToObject.new({
        data: {
          id: uuid,
          type: 'people',
          relationships: {
            non_existent: {
              data: [{ id: SecureRandom.uuid, type: 'hahahhas' }]
            }
          }
        }
      })
      }.to raise_error "`Person' does not have relationship `non_existent'"
    end
  end

  it 'raises an error if the relationship hash is missing an id' do
    params_object = JsonApiRails::ParamsToObject.new({data: {type: 'people'}})
    expect{
      params_object.validate_relationship_hash({type: 'none'})
    }.to raise_error "Field `id' is malformed or missing"
  end

  it 'raises an error if the relationship hash is missing a type' do
    params_object = JsonApiRails::ParamsToObject.new({data: {type: 'people'}})
    expect{
      params_object.validate_relationship_hash({id: 'none'})
    }.to raise_error "Field `type' is malformed or missing"
  end

  it 'raises an error if the id field of the relationship hash is not a string' do
    params_object = JsonApiRails::ParamsToObject.new({data: {type: 'people'}})
    expect{
      params_object.validate_relationship_hash({id: 1, type: 'none'})
    }.to raise_error "Field `id' is malformed or missing"
  end

  it 'raises an error if the type field of the relationship hash is not a string' do
    params_object = JsonApiRails::ParamsToObject.new({data: {type: 'people'}})
    expect{
      params_object.validate_relationship_hash({id: '1', type: ['what']})
    }.to raise_error "Field `type' is malformed or missing"
  end

  describe '#resource' do
    context 'given a model with properly named Resource' do
      subject(:params_object) do
        JsonApiRails::ParamsToObject.new(data: { type: 'people' })
      end

      it 'can resolve and instantiate a Resource' do
        expect(params_object.resource).to be_an_instance_of(PersonResource)
      end
    end

    context 'given a resource_class option' do
      subject(:params_object) do
        JsonApiRails::ParamsToObject.new(
          {
            data: {
              type: 'people'
            }
          },
          nil, {
            resource_class: 'AlternatePersonResource'
          }
        )
      end

      it 'can resolve and instantiate a Resource' do
        expect(params_object.resource).to be_an_instance_of(AlternatePersonResource)
      end
    end
  end
end
