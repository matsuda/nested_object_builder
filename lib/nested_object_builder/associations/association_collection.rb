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
            model.all.each do |m|
              build( foreign_key => m.id ) unless map(&foreign_key).include?(m.id)
            end
            sort!{ |a, b| a.send(foreign_key) <=> b.send(foreign_key) }
            if association = @reflection.options[:builder_include]
              preload_associations(self, association)
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
            sort!{ |a, b| a.send(foreign_key) <=> b.send(foreign_key) }
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
