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
    include_array = []
    relations = model.reflections.keys
    hasharray.each do |e|
      if e.is_a? String
        key = e.split(':')[0]
        include_array.push(key) if relations.include?(key)
      elsif e.is_a? Hash
        key = e.keys.first.split(':')[0]
        relation_model = model.reflections[key].klass
        relation_hasharray = self.query_include(relation_model, e.values.first)
        if relation_hasharray.empty?
          include_array.push(key)
        else
          include_array.push({key => relation_hasharray})
        end
      end
    end
    include_array
  end

  def self.serialize(record, hasharray, options)

    if record.nil?
      return nil
    end

    if record.respond_to? :map
      return record.map do |r|
        self.serialize(r, hasharray, options)
      end
    end

    hash = {}
    model = record.class
    all_relations = model.reflections.keys

    relations = hasharray.filter do |e|
      next true if !e.is_a?(String)

      key, alias_key = e.split(':')
      all_relations.include?(key)
    end

    attributes = hasharray - relations
    attributes = model.attribute_names if attributes.empty?

    attributes.each do |e|
      key, alias_key = e.split(':')
      alias_key = apply_case(alias_key || key, options[:case])

      hash[alias_key] = coerce_value(record.public_send(key))
    end

    relations.each do |e|
      if e.is_a? String
        key, alias_key = e.split(':')
        alias_key = apply_case(alias_key || key, options[:case])

        rel_records = record.public_send(key)
        hash[alias_key] = self.serialize(rel_records, [], options)
      else
        key, alias_key = e.keys.first.split(':')
        alias_key = apply_case(alias_key || key, options[:case])

        rel_records = record.public_send(key)
        hash[alias_key] = self.serialize(rel_records, e.values.first, options)
      end
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
