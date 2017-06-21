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
        body.to_s
      end

      Body = Struct.new(:params) do
        def to_s
          if params.keys.include?("container_method_line_number")
            QUERY
          else
            QUERY_WITHOUT_CONTAINER_METHOD_LINE_NUMBER
          end
        end
      end

      private

      def body
        @body ||= Body.new(params)
      end

      # rubocop:disable Metrics/MethodLength,Metrics/AbcSize
      def calculate_params
        params = {
          "call_site_file"               => @call_site.file,
          "call_site_line_number"        => @call_site.line_number,
          "step_number"                  => @step_number,
          "stack_uuid"                   => @stack_uuid,
          "container_method_klass_name"  => @container_method.klass.to_s,
          "container_method_type"        => @container_method.method_type,
          "container_method_name"        => @container_method.method_name,
          "container_method_file"        => @container_method.file,
          "container_method_line_number" => @container_method.line_number,
          "called_method_klass_name"     => @called_method.klass.to_s,
          "called_method_type"           => @called_method.method_type,
          "called_method_name"           => @called_method.method_name,
          "called_method_file"           => @called_method.file,
          "called_method_line_number"    => @called_method.line_number,
        }

        if @container_method.line_number.nil?
          params.delete "container_method_line_number"
        end

        params
      end
      # rubocop:enable Metrics/MethodLength,Metrics/LineLength,Metrics/AbcSize

      QUERY = <<-QUERY
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

      QUERY_WITHOUT_CONTAINER_METHOD_LINE_NUMBER =
        QUERY.
        split("\n").
        reject { |l| l[/line_number: {container_method_line_number}/] }.
        map { |l| l.gsub "{container_method_file},", "{container_method_file}" }.
        join("\n")
    end
  end
end
