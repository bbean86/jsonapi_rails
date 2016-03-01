module JsonApiRails
  # {Parser} provides a testable interface for wrapping a set of params using
  # `ParamsToObject`, then extracting the model and passing it to the given
  # block.
  class Parser
    def initialize(params_hsh, ar_relation = nil, resource_class = nil, whitelisted = [])
      @wrapper = ParamsToObject.new params_hsh,
                                    ar_relation,
                                    resource_class,
                                    whitelisted
    end

    # Extracts the model from the wrapper, then passes it to the given block.
    def execute(block)
      model = @wrapper.object
      block.call model
    end
  end
end
