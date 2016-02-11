module JsonApiRails
  # {Parser} provides a testable interface for wrapping a set of params using
  # `ParamsToObject`, then extracting the model and passing it to the given
  # block.
  class Parser
    def initialize(params_hsh, ar_relation = nil)
      @wrapper = ParamsToObject.new params_hsh, ar_relation
    end

    # Extracts the model from the wrapper, then passes it to the given block.
    def execute(block)
      model = @wrapper.object
      block.call model
    end
  end
end
