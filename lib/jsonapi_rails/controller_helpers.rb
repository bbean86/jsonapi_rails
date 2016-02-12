module JsonApiRails
  # Namespace for helpers to be used in `ActionController::Base` descendants.
  module ControllerHelpers
    # Prepares included relationship names for use in JsonApi.serialize. It
    # expects a list of symbols.
    # @return [Array] list of symbolized relationship names
    def includes
      params.fetch(:include, '').split(',').map(&:to_sym)
    end

    # Parses `params_hsh` and passes the resulting model to the given block.
    # Rescues and renders any errors encountered when parsing.
    def parse_json_api_params(params_hsh, ar_relation = nil, &block)
      parser = Parser.new params_hsh, ar_relation
      parser.execute block
    rescue Error => exception
      render json_api_errors: [exception.message]
    end
  end
end
