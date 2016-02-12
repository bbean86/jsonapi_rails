require 'rails/railtie'

module JsonApiRails
  # Handles registering the JSONAPI mime type and adding the `json_api` and
  # `json_api_errors` renderers.
  class Railtie < Rails::Railtie
    initializer 'railtie.configure_rails_renderers' do
      # Registers the JSONAPI mime type
      Mime::Type.register(JsonApiRails::MIMETYPE, :json_api)
      mime_type = Mime::Type.lookup(JsonApiRails::MIMETYPE)
      ActionDispatch::ParamsParser::DEFAULT_PARSERS[mime_type] = lambda do |body|
        JSON.parse(body)
      end

      # Adds `json_api_errors` to the list of available renderers. Passes the
      # given object to the JsonApi gem for serialization. Sets response status
      # to 422 by default.
      ActionController::Renderers.add :json_api_errors do |object, options|
        json = JsonApi.serialize_errors(object).to_json
        self.content_type ||= JsonApiRails::MIMETYPE
        self.status = options[:status] || 422
        json
      end

      # Adds `json_api` to the list of available renderers. Passes the given
      # object and options to the JsonApi gem for serialization.
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
