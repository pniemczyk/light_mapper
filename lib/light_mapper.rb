require 'light_mapper/version'

module LightMapper
  BaseError = Class.new(StandardError)
  InvalidKey = Class.new(BaseError)
  KeyMissing = Class.new(BaseError)
  InvalidStructure = Class.new(BaseError)
  AlreadyAssignedValue = Class.new(BaseError)

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

    def self.build_structure(mapping)
      mapping.values.each_with_object({}) do |value, result|
        nesting = value.to_s.split('.')[0..-2]
        next result if nesting.empty?

        nesting.each do |key|
          result[key] ||= {}
          result = result[key]
        end
      end
    end

    def self.push(hash, key, value, keys: :string, build_structure: true, override: false)
      return hash[key] = value if key.is_a?(Symbol)

      path = key.to_s.split('.')
      path = path.map(&:to_sym) if keys == :symbol

      context = hash
      context[path.first] if build_structure && path.size == 2

      path.each_with_index do |k, idx|
        last_idx = idx == path.size - 1
        raise AlreadyAssignedValue, "Key #{k} already assigned in #{path} for #{hash.inspect} structure" if !override && last_idx && context.key?(k) && !context[k].nil?
        next context[k] = value if last_idx && context.is_a?(Hash)

        context.send(:[]=,k, {}) if build_structure && !context.key?(k)
        context.is_a?(Hash) ? context = context.send(:[], k) : break
      end
    end

    def self.compact(hash)
      hash.each_with_object({}) do |(key, value), result|
        next if value.empty?

        result[key] = value.is_a?(Hash) ? compact(value) : value
      end
    end
  rescue IndexError
    raise InvalidStructure, "Invalid key: #{key} for #{hash.inspect} structure"
  end

  def mapping(mappings, opts = {})
    LightMapper.mapping(clone, mappings, opts)
  end

  def push(key, value, keys: :string, build_structure: true, override: false)
    LightMapper::Helper.push(self, key, value, keys: keys, build_structure: build_structure, override: override)
    self
  end

  def self.mapping(hash, mappings, opts = {})
    strict, any_keys, keys = opts.values_at(:strict, :any_keys, :keys)

    mappings.each_with_object({}) do |(k, v), h|
      next Helper.push(h, v, k.call(hash), keys: keys) if k.is_a?(Proc)

      key_path = Helper.key_destructor(k)
      value = Helper.value_extractor(hash, key_path.first, key_path[1..-1], key_path, strict, any_keys)
      Helper.push(h, v, value, keys: keys)
    end
  end
end
