# frozen_string_literal: true

module Delfos
  module Neo4j
    class CallSiteQuery
      def initialize(call_site, stack_uuid, step_number)
        @call_site        = call_site
        @container_method = call_site.container_method
        @called_method    = call_site.called_method
        @stack_uuid       = stack_uuid
        @step_number      = step_number
      end

      def params
        @params ||= calculate_params
      end

      def query
        BODY
      end

      private

      # rubocop:disable Metrics/MethodLength
      def calculate_params
        params = {
          "step_number"                  => @step_number,
          "stack_uuid"                   => @stack_uuid,

          "call_site_file"               => @call_site        .file,
          "call_site_line_number"        => @call_site        .line_number,

          "container_method_klass_name"  => @container_method .klass_name,
          "container_method_type"        => @container_method .method_type,
          "container_method_name"        => @container_method .method_name,
          "container_method_file"        => @container_method .file,
          "container_method_line_number" => @container_method .line_number || -1,

          "called_method_klass_name"     => @called_method    .klass_name,
          "called_method_type"           => @called_method    .method_type,
          "called_method_name"           => @called_method    .method_name,
          "called_method_file"           => @called_method    .file,
          "called_method_line_number"    => @called_method    .line_number,
        }

        params
      end
      # rubocop:enable Metrics/MethodLength

      BODY = <<-QUERY
          MERGE (container_method_klass:Class {name: {container_method_klass_name}})
          MERGE (called_method_klass:Class {name: {called_method_klass_name}})

          MERGE (container_method_klass) - [:OWNS] ->
            (container_method:Method
              {
                type: {container_method_type},
                name: {container_method_name},
                file: {container_method_file},
                line_number: {container_method_line_number}
              }
            )
          MERGE (container_method) - [:CONTAINS] ->
            (call_site:CallSite
              {
                file: {call_site_file},
                line_number: {call_site_line_number}
              }
            )

          MERGE (called_method_klass) - [:OWNS] ->
            (called_method:Method
              {
                type: {called_method_type},
                name: {called_method_name},
                file: {called_method_file},
                line_number: {called_method_line_number}
              }
            )

          MERGE (call_site) - [:CALLS] -> (called_method)

          MERGE (call_stack:CallStack{uuid: {stack_uuid}})

          MERGE (call_stack) - [:STEP {number: {step_number}}] -> (call_site)
      QUERY
    end
  end
end
