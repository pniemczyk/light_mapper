require 'light_mapper/version'

module LightMapper
  def mapping(mappings, opts = {})
    LightMapper.mapping(clone, mappings, opts)
  end

  def self.mapping(hash, mappings, opts = {})
    require_keys  = opts[:require_keys]  == true
    any_keys_kind = opts[:any_keys_kind] == true
    fetch_method  = if any_keys_kind
      if require_keys
        -> (hash, key) { hash.fetch(key.to_s, hash.fetch(key.to_sym)) }
      else
        -> (hash, key) { hash[key.to_s] || hash[key.to_sym] }
      end
    else
      if require_keys
        -> (hash, key) { hash.fetch(key) }
      else
        -> (hash, key) { hash[key] }
      end
    end

    {}.tap do |h|
      mappings.each { |k, v| h[v] = fetch_method.call(hash, k) }
    end
  end
end
