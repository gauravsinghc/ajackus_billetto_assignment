class Fact < RubyEventStore::Event
  def self.strict(data:, metadata: {})
    if defined?(self::SCHEMA)
      self::SCHEMA.each do |key, type|
        unless data.key?(key) && data[key].is_a?(type)
          raise ArgumentError, "Invalid data for #{key}: expected #{type}, got #{data[key].class}"
        end
      end
    end
    new(data: data, metadata: metadata)
  end
end