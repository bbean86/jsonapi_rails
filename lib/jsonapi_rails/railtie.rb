require 'rails/railtie'

module JsonApiRails
  class Railtie < Rails::Railtie
    initializer 'railtie.configure_rails_renderers' do
      Mime::Type.register(JsonApiRails::MIMETYPE, :json_api)

      mime_type = Mime::Type.lookup(JsonApiRails::MIMETYPE)
      ActionDispatch::ParamsParser::DEFAULT_PARSERS[mime_type] = lambda do |body|
        JSON.parse(body)
      end

      ActionController::Renderers.add :json_api_errors do |object, options|
        json = JsonApi.serialize_errors(object).to_json
        self.content_type ||= JsonApiRails::MIMETYPE
        self.status = options[:status] || 422
        json
      end

      ActionController::Renderers.add :json_api do |object, options|
        json =
          if object.is_a?(Hash)
            object.to_json options
          else
            JsonApi.serialize(object, options).to_json unless object.is_a?(String)
          end

        self.content_type ||= JsonApiRails::MIMETYPE
        json
      end
    end
  end
end
