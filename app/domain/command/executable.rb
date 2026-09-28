module Command
  module Executable
    extend ActiveSupport::Concern
    
    included do
      include ActiveModel::Model
      include ActiveModel::Attributes
    end
    
    def execute
      raise ActiveModel::ValidationError, self unless valid?
      call
    end
  end
end