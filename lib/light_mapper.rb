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
                        -> (h, k) { h.fetch(k.to_s, h.fetch(k.to_sym)) }
                      else
                        -> (h, k) { h[k.to_s] || h[k.to_sym] }
                      end
                    else
                      if require_keys
                        -> (h, k) { h.fetch(k) }
                      else
                        -> (h, k) { h[k] }
                      end
                    end
    {}.tap do |h|
      mappings.each { |k, v| h[v] = fetch_method.call(hash, k) }
    end
  end
end
