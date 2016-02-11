require 'spec_helper'

describe JsonApiRails::Parser do
  describe '#execute' do
    let(:person) { Person.create! name: 'Ben' }
    let(:params) { JSON.parse(JsonApi.serialize(person).to_hash.to_json, symbolize_names: true) }
    let(:parser) { JsonApiRails::Parser.new params }
    let(:block) { proc { |person| "Proc was called by #{person.name}" } }
    subject(:message) { parser.execute block }

    it 'passes the model to the given proc' do
      expected_message = 'Proc was called by Ben'
      expect(message).to eq(expected_message)
    end
  end
end
