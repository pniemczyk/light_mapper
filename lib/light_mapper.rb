require 'light_mapper/version'

module LightMapper
  def mapping(mappings, opts = {})
    LightMapper.mapping(clone, mappings, opts)
  end

  def self.mapping(hash, mappings, opts = {})
    method_name_parts = opts.each_with_object([]) { |(key, value), arr| arr << key.to_s if value == true  }.sort
    method_name       = method_name_parts.empty? ? '_default_extraction' : "_#{method_name_parts.join('_and_')}_extraction"
    fetch_method      = method(method_name)
    mappings.each_with_object({}) do |(k, v), h|
      h[v] = fetch_method.call(hash, k)
    end
  end

  private

  def self._any_keys_kind_and_require_keys_extraction(hash, key)
    hash.fetch(key.to_s, hash.fetch(key.to_sym))
  end

  def self._any_keys_kind_extraction(hash, key)
    hash[key.to_s] || hash[key.to_sym]
  end

  def self._require_keys_extraction(hash, key)
    hash.fetch(key)
  end

  def self._default_extraction(hash, key)
    hash[key]
  end
end
