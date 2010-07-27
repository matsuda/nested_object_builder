module NestedObjectBuilder
  module NestedAttributes #:nodoc:
    def self.included(base)
      base.send :include, InstanceMethods
      base.class_eval do
        alias_method_chain :assign_nested_attributes_for_one_to_one_association, :nested_checked
        alias_method_chain :assign_nested_attributes_for_collection_association, :nested_checked
      end
    end

    # module ClassMethods
    #   
    # end

    module InstanceMethods
      def _nested_checked
        instance_variable_get(:@_nested_checked)
      end

      private
      def mark_for_nested_checked(record, attributes)
        if has_destroy_flag?(attributes)
          record.instance_variable_set(:@_nested_checked, false)
        else
          record.instance_variable_set(:@_nested_checked, true)
        end
      end

      def assign_nested_attributes_for_one_to_one_association_with_nested_checked(association_name, attributes)
        options = nested_attributes_options[association_name]
        attributes = attributes.with_indifferent_access
        check_existing_record = (options[:update_only] || !attributes['id'].blank?)

        if check_existing_record && (record = send(association_name)) &&
            (options[:update_only] || record.id.to_s == attributes['id'].to_s)
          assign_to_or_mark_for_destruction(record, attributes, options[:allow_destroy])
          mark_for_nested_checked(record, attributes)

        elsif attributes['id']
          raise_nested_attributes_record_not_found(association_name, attributes['id'])

        elsif !reject_new_record?(association_name, attributes)
          method = "build_#{association_name}"
          if respond_to?(method)
            record = send(method, attributes.except(*ActiveRecord::NestedAttributes::UNASSIGNABLE_KEYS))
            mark_for_nested_checked(record, attributes)
          else
            raise ArgumentError, "Cannot build association #{association_name}. Are you trying to build a polymorphic one-to-one association?"
          end
        end
      end

      def assign_nested_attributes_for_collection_association_with_nested_checked(association_name, attributes_collection)
        options = nested_attributes_options[association_name]

        unless attributes_collection.is_a?(Hash) || attributes_collection.is_a?(Array)
          raise ArgumentError, "Hash or Array expected, got #{attributes_collection.class.name} (#{attributes_collection.inspect})"
        end

        if options[:limit] && attributes_collection.size > options[:limit]
          raise TooManyRecords, "Maximum #{options[:limit]} records are allowed. Got #{attributes_collection.size} records instead."
        end

        if attributes_collection.is_a? Hash
          attributes_collection = attributes_collection.sort_by { |index, _| index.to_i }.map { |_, attributes| attributes }
        end

        association = send(association_name)

        existing_records = if association.loaded?
          association.to_a
        else
          attribute_ids = attributes_collection.map {|a| a['id'] || a[:id] }.compact
          attribute_ids.present? ? association.all(:conditions => {association.primary_key => attribute_ids}) : []
        end

        attributes_collection.each do |attributes|
          attributes = attributes.with_indifferent_access

          if attributes['id'].blank?
            unless reject_new_record?(association_name, attributes)
              record = association.build(attributes.except(*ActiveRecord::NestedAttributes::UNASSIGNABLE_KEYS))
              mark_for_nested_checked(record, attributes)
            end
          elsif existing_record = existing_records.detect { |record| record.id.to_s == attributes['id'].to_s }
            association.send(:add_record_to_target_with_callbacks, existing_record) unless association.loaded?
            assign_to_or_mark_for_destruction(existing_record, attributes, options[:allow_destroy])
            mark_for_nested_checked(existing_record, attributes)
          else
            raise_nested_attributes_record_not_found(association_name, attributes['id'])
          end
        end
      end
    end

  end
end

ActiveRecord::Base.send :include, NestedObjectBuilder::NestedAttributes
