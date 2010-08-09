module NestedObjectBuilder
  module Associations
    class NotFoundHasManyAssociationBuildsOption < ActiveRecord::ActiveRecordError
      def initialize(reflection)
        super("Could not find the :builder_count, :builder, :builder_include options in => [#{reflection.options.keys.join(", ")}].  Try 'has_many #{reflection.name.inspect}, :builder_count => <build_records_count>, :builder => <reflections>, :builder_include => <reflection>'")
      end
    end

    module AssociationCollection
      def self.included(base)
        base.send :include, InstanceMethods
      end

      module InstanceMethods
        def builds_prepare(attributes = {}, &block)
          if count = @reflection.options[:builder_count]
            # returning records = [] do
            #   (size..count-1).step {|i| records << build(attributes, &block)}
            # end
          elsif builder = @reflection.options[:builder]
            model       = builder.to_s.singularize.camelize.constantize
            foreign_key = model.to_s.foreign_key.to_sym
            if association = @reflection.options[:builder_include]
              preload_associations(self, association)
            end
            load_target
          end
        end

        def builds(attributes = {}, &block)
          if count = @reflection.options[:builder_count]
            # returning records = [] do
            #   (size..count-1).step {|i| records << build(attributes, &block)}
            # end
          elsif builder = @reflection.options[:builder]
            model       = builder.to_s.singularize.camelize.constantize
            foreign_key = model.to_s.foreign_key.to_sym
            builder_ids = model.all.map(&:id)
            builder_ids.each do |builder_id|
              build( foreign_key => builder_id ) unless map(&foreign_key).include?(builder_id)
            end
            if association = @reflection.options[:builder_include]
              preload_associations(self, association)
            end
            reject!{ |bld| !builder_ids.include?(bld.send(foreign_key)) }
            sort_key = @reflection.options[:builder_order] || foreign_key
            case sort_key
            when Symbol
              sort!{ |a, b| a.send(sort_key) <=> b.send(sort_key) }
            when Proc
              sort!{ |a, b| sort_key.call(a) <=> sort_key.call(b) }
            end
            load_target
          else
            raise NotFoundHasManyAssociationBuildsOption.new(@reflection)
          end
        end

        def builder_expectants(attributes = {}, &block)
          if count = @reflection.options[:builder_count]
            # returning records = [] do
            #   (size..count-1).step {|i| records << build(attributes, &block)}
            # end
          elsif builder = @reflection.options[:builder]
            model       = builder.to_s.singularize.camelize.constantize
            foreign_key = model.to_s.foreign_key.to_sym
            if association = @reflection.options[:builder_include]
              preload_associations(self, association)
            end
            sort_key = @reflection.options[:builder_order] || foreign_key
            case sort_key
            when Symbol
              sort!{ |a, b| a.send(sort_key) <=> b.send(sort_key) }
            when Proc
              sort!{ |a, b| sort_key.call(a) <=> sort_key.call(b) }
            end
            # load_target
            reject{ |association| !association._nested_checked }
          else
            raise NotFoundHasManyAssociationBuildsOption.new(@reflection)
          end
        end
      end
    end
  end
end

ActiveRecord::Associations::AssociationCollection.send :include, NestedObjectBuilder::Associations::AssociationCollection
