module ActiveRecord
  module Associations # :nodoc:
    HAS_MANY_BUILDER_ASSOCIATION_KEYS = [:builder_count, :builder, :builder_include, :builder_order]

    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods
      @@valid_keys_for_has_many_association << HAS_MANY_BUILDER_ASSOCIATION_KEYS
    end
  end
end

# ActiveRecord::Base.send :include, ActiveRecord::Associations
