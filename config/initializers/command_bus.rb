class SimpleCommandBus
  def initialize
    @handlers = {}
  end

  def register(command_class, handler_instance, method_name)
    @handlers[command_class] = { instance: handler_instance, method: method_name }
  end

  def call(command)
    execution_id = SecureRandom.uuid

    ApplicationRecord.transaction do
      Rails.configuration.event_store.with_metadata(correlation_id: execution_id) do
        execute_command(command)
      end
    end
  end

  private

  def execute_command(command)
    if @handlers.key?(command.class)
      handler = @handlers[command.class]
      handler[:instance].public_send(handler[:method], command)
    elsif command.respond_to?(:execute)
      command.execute
    else
      raise "No handler registered for #{command.class}"
    end
  end
end

Rails.application.config.command_bus = SimpleCommandBus.new

module CommandBusHelper
  def command_bus
    Rails.configuration.command_bus
  end
end

ActiveSupport.on_load(:action_controller) do
  include CommandBusHelper
end

Rails.application.config.to_prepare do
  bus = Rails.configuration.command_bus
  
  if defined?(Voting::Service)
    service = Voting::Service.new
    Voting::Service.handlers.each do |command_class, method_name|
      bus.register(command_class, service, method_name)
    end
  end
end
