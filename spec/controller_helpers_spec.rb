require 'spec_helper'
class ControllerMock
  include JsonApiRails::ControllerHelpers

  attr_accessor :params

  def initialize(params = {})
    @params = params
  end
end

describe JsonApiRails::ControllerHelpers do
  let(:controller) { ControllerMock.new }
  describe 'includes' do
    before { controller.params[:include] = 'foo,bar' }
    subject(:includes) { controller.includes }

    it 'returns a map of symbolized names' do
      symbolized_names = [:foo, :bar]
      expect(includes).to eq symbolized_names
    end

    context 'deeply-nested' do
      before { controller.params[:include] = 'foo, bar.baz, bar.baz.qux, bar.baz.qux.norf, foo' }
      it 'returns a map of symbolized names and hashes' do
        names_and_hashes = [:foo, { bar: { baz: { qux: :norf } } }]
        expect(includes).to eq names_and_hashes
      end
    end
  end
end
