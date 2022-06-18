require "gql_serializer/version"
require "gql_serializer/extensions"
require "gql_serializer/configuration"


module GqlSerializer

  def self.configuration
    @configuration ||= Configuration.new
  end

  def self.configure
    yield configuration
  end


  def self.parse_query(input)
    query = input.dup
    query.strip!
    query.gsub!(/[\r\n\t ]+/, ' ')
    query.gsub!(/\{ /, '{')
    query.gsub!(/ }/, '}')

    result, _ = self.parse_it(query)
    result
  end

  def self.query_include(model, hasharray)
    return [] if !model.respond_to? :reflections
    include_array = []
    relations = model.reflections
    hasharray.each do |element|
      if element.is_a? String
        key = element.split(':')[0]
        include_array.push(key) if relations[key]
      elsif element.is_a? Hash
        key = element.keys.first.split(':')[0]
        relation_model = model.reflections&.[](key)&.klass
        next if relation_model.nil?
        relation_hasharray = self.query_include(relation_model, element.values.first)
        if relation_hasharray.empty?
          include_array.push(key)
        else
          include_array.push({key => relation_hasharray})
        end
      end
    end
    include_array
  end

  # example hasharray = ["id", "name:real_name", "tags", { "panels" => ["id", { "cards" => ["content"] }] }]
  def self.serialize(records, hasharray, options, instructions = {})

    if records.nil?
      return nil
    end

    if records.is_a?(Hash)
      return self.serialize_hash(records, hasharray, options, instructions)
    end

    if records.respond_to? :map
      return records.map do |record|
        self.serialize(record, hasharray, options, instructions)
      end
    end

    if records.class.respond_to? :reflections
      return self.serialize_active_record(records, hasharray, options, instructions)
    end

    if !hasharray.empty?
      return self.serialize_object(records, hasharray, options, instructions)
    end
    
    return coerce_value(records)
  end

  def self.serialize_active_record(record, hasharray, options, instructions = {})
    id = "#{record.class}, #{hasharray}"
    instruction = instructions[id]
    if (!instruction)
      instruction = {klass: record.class, hasharray: hasharray, attributes: []}
      instructions[id] = instruction

      model = record.class
      all_relations = model.reflections.keys
      relations = hasharray.filter do |relation|
        key, _ = self.get_keys(relation, options)
        all_relations.include?(key)
      end

      if (hasharray - relations).empty?
        attributes = model.attribute_names + relations
      else
        attributes = hasharray
      end

      attributes.each do |attribute|
        key, alias_key, sub_hasharray = self.get_keys(attribute, options)
        instruction[:attributes].push({key: key, alias_key: alias_key, hasharray: sub_hasharray})
      end
    end

    hash = {}
    instruction[:attributes].each do |attribute|
      value = record.public_send(attribute[:key])
      hash[attribute[:alias_key]] = self.serialize(value, attribute[:hasharray], options, instructions)
    end

    hash
  end

  def self.serialize_object(record, hasharray, options, instructions = {})
    hash = {}

    hasharray.each do |attribute|
      key, alias_key, sub_hasharray = self.get_keys(attribute, options)
      value = record.public_send(key)
      hash[alias_key] = self.serialize(value, sub_hasharray, options, instructions)
    end

    hash
  end

  def self.serialize_hash(record, hasharray, options, instructions = {})
    hash = {}
    attributes = hasharray.empty? ? record.keys : hasharray

    attributes.each do |attribute|
      key, alias_key, sub_hasharray = self.get_keys(attribute, options)
      value = self.get_hash_value(record, key)
      hash[alias_key] = self.serialize(value, sub_hasharray, options, instructions)
    end

    hash
  end

  def self.coerce_value(value)
    return value.to_f if value.is_a? BigDecimal
    return value.new_offset(0).strftime("%FT%TZ") if value.is_a? DateTime
    return value.utc.iso8601 if value.is_a? Time
    value
  end


  private

  def self.apply_case(key, key_case)
    case key_case
    when Configuration::CAMEL_CASE
      result = key.camelize
      result[0] = result[0].downcase
    when Configuration::SNAKE_CASE
      result = key.underscore
    else
      result = key
    end

    result
  end

  def self.get_hash_value(hash, key)
    return hash[key] if hash.key?(key)
    return hash[key.to_sym] if hash.key?(key.to_sym)
    raise NoMethodError, "undefined field '#{key.to_s}' for #{hash}"
  end

  def self.get_keys(attribute, options)
    if attribute.is_a?(Symbol)
      key, alias_key = attribute.to_s.split(':')
      hasharray = []
    elsif attribute.is_a?(String)
      key, alias_key = attribute.split(':')
      hasharray = []
    else
      key, alias_key = attribute.keys.first.split(':')
      hasharray = attribute.values.first
    end
    alias_key = apply_case(alias_key || key, options[:case])
    [key, alias_key, hasharray]
  end

  def self.parse_it(query)
    result = []
    while query&.length&.> 0
      if query[0] == ' '
        query.strip!
        next
      elsif query[0] == '}'
        return result, query[1..-1]
      end

      next_key = query[/[_a-zA-Z0-9:]+/]
      query = query[next_key.length..-1]
      query.strip!

      if query.nil? || query.empty? || query[0].match?(/[_a-zA-Z0-9:]/)
        result.push(next_key)

      elsif query&.[](0) == '{'
        query = query[1..-1]
        obj, query = parse_it(query)
        result.push(next_key => obj)

      elsif query[0] == '}'
        result.push(next_key)
        return result, query[1..-1]

      else
        raise "unsupported character '#{query[0]}'"

      end
    end
    return result, nil
  end

end
