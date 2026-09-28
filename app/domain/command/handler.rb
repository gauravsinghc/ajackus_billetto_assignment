module Command
  module Handler
    extend ActiveSupport::Concern
    class_methods do
      def handles(command_class, method_name)
        @handlers ||= {}
        @handlers[command_class] = method_name
      end
      def handlers
        @handlers || {}
      end
    end
  end
end