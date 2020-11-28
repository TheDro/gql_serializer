require "gql_serializer/version"
require "gql_serializer/extensions"


module GqlSerializer

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

  def self.serialize(record, hasharray)

    if record.nil?
      return nil
    end

    if record.respond_to? :map
      return record.map do |r|
        self.serialize(r, hasharray)
      end
    end

    hash = {}
    model = record.class

    attributes = hasharray.filter do |e|
      next false if !e.is_a?(String)

      key, alias_key = e.split(':')
      model.attribute_names.include?(key)
    end

    relations = hasharray - attributes
    attributes = model.attribute_names if attributes.empty?

    attributes.each do |e|
      key, alias_key = e.split(':')
      alias_key ||= key
      hash[alias_key] = record.public_send(key)
    end

    relations.each do |e|
      if e.is_a? String
        key, alias_key = e.split(':')
        alias_key ||= key
        rel_records = record.public_send(key)
        hash[alias_key] = self.serialize(rel_records, [])
      else
        key, alias_key = e.keys.first.split(':')
        alias_key ||= key
        rel_records = record.public_send(key)
        hash[alias_key] = self.serialize(rel_records, e.values.first)
      end
    end

    hash
  end


  private

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
