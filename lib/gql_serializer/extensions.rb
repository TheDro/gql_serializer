require "active_record"

module GqlSerializer
  module Array
    def as_gql(query = nil)
      map { |v| v.as_gql(query) }
    end
  end

  module Relation
    def as_gql(query = nil, options = {})
      query_hasharray = query ? GqlSerializer.parse_query(query) : []
      include_hasharray = GqlSerializer.query_include(self.model, query_hasharray)
      records = self.includes(include_hasharray).records
      options_with_defaults = GqlSerializer.configuration.to_h.merge(options)
      GqlSerializer.serialize(records, query_hasharray, options_with_defaults)
    end
  end

  module ActiveRecord
    def self.as_gql(query = nil, options = {})
      self.all.as_gql(query, options)
    end

    def as_gql(query = nil, options = {})

      query_hasharray = query ? GqlSerializer.parse_query(query) : []
      include_hasharray = GqlSerializer.query_include(self.class, query_hasharray)
      record = include_hasharray.empty? ? self : self.class.where(id: self).includes(include_hasharray).first
      options_with_defaults = GqlSerializer.configuration.to_h.merge(options)
      GqlSerializer.serialize(record, query_hasharray, options_with_defaults)
    end
  end
end

ActiveRecord::Base.include GqlSerializer::ActiveRecord
ActiveRecord::Relation.include GqlSerializer::Relation
Array.include GqlSerializer::Array