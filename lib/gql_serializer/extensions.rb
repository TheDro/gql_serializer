require "active_record"

module GqlSerializer
  module Array
    def as_gql(...)
      map { |v| v.as_gql(...) }
    end
  end

  module Hash
    def as_gql(query = nil, options = {})
      options_with_default = GqlSerializer.configuration.to_h.merge(options)
      query_hasharray = query ? GqlSerializer.parse_query(query) : []
      GqlSerializer.serialize(self, query_hasharray, options_with_default)
    end
  end

  module Relation
    def as_gql(query = nil, options = {})
      options_with_defaults = GqlSerializer.configuration.to_h.merge(options)
      query_hasharray = query ? GqlSerializer.parse_query(query) : []
      include_hasharray = GqlSerializer.query_include(self.model, query_hasharray)
      records = self.includes(include_hasharray).records
      GqlSerializer.serialize(records, query_hasharray, options_with_defaults)
    end
  end

  module ActiveRecord
    def self.as_gql(query = nil, options = {})
      self.all.as_gql(query, options)
    end

    def as_gql(query = nil, options = {})
      options_with_defaults = GqlSerializer.configuration.to_h.merge(options)
      query_hasharray = query ? GqlSerializer.parse_query(query) : []
      include_hasharray = GqlSerializer.query_include(self.class, query_hasharray)
      if options_with_defaults[:preload]
        GqlSerializer._preload([self], include_hasharray)
        GqlSerializer.serialize(self, query_hasharray, options_with_defaults)
      else
        record = include_hasharray.empty? ? self : self.class.where(id: self).includes(include_hasharray).first
        GqlSerializer.serialize(record, query_hasharray, options_with_defaults)
      end
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
Hash.include GqlSerializer::Hash