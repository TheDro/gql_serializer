require "active_record"

module GqlSerializer
  module Array
    def as_gql(query = nil)
      map { |v| v.as_gql(query) }
    end
  end

  module Relation
    def as_gql(query = nil)
      query_hasharray = query ? GqlSerializer.parse_query(query) : []
      include_hasharray = GqlSerializer.query_include(self.model, query_hasharray)
      records = self.includes(include_hasharray).records
      GqlSerializer.serialize(records, query_hasharray)
    end
  end

  module ActiveRecord
    def self.as_gql(query = nil)
      self.all.as_gql(query)
    end

    def as_gql(query = nil)

      query_hasharray = query ? GqlSerializer.parse_query(query) : []
      include_hasharray = GqlSerializer.query_include(self.class, query_hasharray)
      record = include_hasharray.empty? ? self : self.class.where(id: self).includes(include_hasharray).first
      GqlSerializer.serialize(record, query_hasharray)
    end
  end
end

ActiveRecord::Base.include GqlSerializer::ActiveRecord
ActiveRecord::Relation.include GqlSerializer::Relation
Array.include GqlSerializer::Array