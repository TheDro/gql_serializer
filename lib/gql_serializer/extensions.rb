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
      GqlSerializer._preload([self], include_hasharray)
      options_with_defaults = GqlSerializer.configuration.to_h.merge(options)
      GqlSerializer.serialize(self, query_hasharray, options_with_defaults)
    end
  end

  def self._preload(records, include_hasharray)
    if ::ActiveRecord::VERSION::MAJOR >= 7
      ::ActiveRecord::Associations::Preloader.
        new(records: records, associations: include_hasharray).call
    else
      ::ActiveRecord::Associations::Preloader.
        new.preload(records, include_hasharray)
    end
  end
end

ActiveRecord::Base.include GqlSerializer::ActiveRecord
ActiveRecord::Relation.include GqlSerializer::Relation
Array.include GqlSerializer::Array