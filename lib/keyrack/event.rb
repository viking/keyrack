module Keyrack
  class Event
    attr_reader :owner, :name, :parent
    attr_accessor :attribute_name, :previous_value, :new_value,
      :collection_name, :object

    def initialize(owner, name, parent = nil)
      @owner = owner
      @name = name
      @parent = parent
    end
  end
end
