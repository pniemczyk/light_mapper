require 'light_mapper/version'

module LightMapper
  InvalidKey = Class.new(StandardError)
  KeyMissing = Class.new(StandardError)

  module Helper
    def self.raise_key_missing(current, full_path, additional_message = nil)

      raise KeyMissing, ["#{current} key not found; Full path #{full_path.map(&:to_s).join('.')}", additional_message].compact.join('; ')
    end

    def self.key_destructor(value)
      case value
      in String
        value.split('.')
      in Symbol
        [value]
      in Array
        value
      else
        raise InvalidKey, "Invalid key type: #{value.class}"
      end
    end

    def self.value_extractor(object, current, path, full_path, strict = false, any_keys = false)
      result = case object
               in Hash
                 hash_key_extractor(object, current, full_path, strict, any_keys)
               in Array
                 array_key_extractor(object, current, full_path, strict, any_keys)
              in NilClass
                 nil
              else
                method_name = current.to_s.to_sym
                object.respond_to?(method_name) ? object.send(method_name) : !strict ? nil : raise_key_missing(current, full_path)
              end

      path.compact.empty? ? result : value_extractor(result, path.first, path[1..-1], full_path, strict, any_keys)
    end

    def self.hash_key_extractor(object, current, full_path, strict, any_keys)
      keys = any_keys ? [current, current.to_s, current.to_s.to_sym] : [current]
      raise_key_missing(current, full_path) if strict && !keys.any? { |k| object.key?(k) }

      object.values_at(*keys).compact.first
    end

    def self.array_key_extractor(object, current, full_path, strict, _any_keys)
      index = current.to_s.match(/^(\d)+$/) ? current.to_i : nil

      if index
        raise_key_missing(current, full_path) if strict && index && object.size < index.next

        object[index]
      else
        method_name = current.to_s.to_sym
        raise_key_missing(current, full_path, "Array do not respond on #{method_name}") if strict && !object.respond_to?(method_name)

        object.public_send(method_name)
      end
    end
  end

  def mapping(mappings, opts = {})
    LightMapper.mapping(clone, mappings, opts)
  end

  def self.mapping(hash, mappings, opts = {})
    strict, any_keys = opts.values_at(:strict, :any_keys)
    mappings.each_with_object({}) do |(k, v), h|
      next h[v] = k.call(hash) if k.is_a?(Proc)

      key_path = Helper.key_destructor(k)
      h[v] = Helper.value_extractor(hash, key_path.first, key_path[1..-1], key_path, strict, any_keys)
    end
  end
end
