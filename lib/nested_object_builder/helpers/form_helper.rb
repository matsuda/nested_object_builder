# -*- coding: utf-8 -*-
module NestedObjectBuilder  
  module Helpers  
    module FormBuilder

      def nested_fields_check_box(builder, builder_id)
        (@object.id.present? ? @template.hidden_field(@object_name, :id, :value => @object.send(:id)) : '') +
        @template.hidden_field(@object_name, builder_id, :value => @object.send(builder_id)) +
        @template.check_box(
          @object_name,
          :_destroy,
          { :checked => @object._nested_checked.nil? ? @object.id.present? : @object._nested_checked },
          '0', '1'
        ) +
        @template.label(@object_name, :_destroy, @object.send(builder).name)
      end

      def nested_fields_hidden_field(builder_id)
        @template.hidden_field(@object_name, builder_id, :value => @object.send(builder_id)) +
        @template.hidden_field(@object_name, :_destroy, :value => @object.send(:_destroy))
      end

    end
  end  
end

ActionView::Helpers::FormBuilder.send :include, NestedObjectBuilder::Helpers::FormBuilder
