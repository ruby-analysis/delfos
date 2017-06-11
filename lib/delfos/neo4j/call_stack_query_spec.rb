# frozen_string_literal: true
require_relative "call_stack_query"
require "./fixtures/a"

module Delfos
  module Neo4j
    RSpec.describe CallStackQuery do
      describe "params" do
        let(:call_sites) { [cs_1, cs_2, cs_3] }
        let(:cs_1) { double "CallSite", file: "file_cs1", line_number: 4, container_method: cm_1, called_method: called_1 }
        let(:cs_2) { double "CallSite", file: "file_cs2", line_number: 5, container_method: cm_2, called_method: called_2 }
        let(:cs_3) { double "CallSite", file: "file_cs3", line_number: 6, container_method: cm_3, called_method: called_3 }

        let(:cm_1) { double "ContainerMethod", file: "file_container_method1", line_number: 1, klass: container_klass_1, method_name: "some_method",        method_type: "ClassMethod" }
        let(:cm_2) { double "ContainerMethod", file: "file_container_method2", line_number: 2, klass: container_klass_2, method_name: "another_method",     method_type: "InstanceMethod"}
        let(:cm_3) { double "ContainerMethod", file: "file_container_method3", line_number: 3, klass: container_klass_3, method_name: "yet_another_method", method_type: "ClassMethod"}
        let(:container_klass_1) { A }
        let(:container_klass_2) { B }
        let(:container_klass_3) { A }

        let(:called_1) { double "CalledMethod", file: "file_called_method1", line_number: 7, klass: called_klass_1, method_name: "a_method", method_type: "ClassMethod" }
        let(:called_2) { double "CalledMethod", file: "file_called_method2", line_number: 8, klass: called_klass_2, method_name: "b_method", method_type: "InstanceMethod"}
        let(:called_3) { double "CalledMethod", file: "file_called_method3", line_number: 9, klass: called_klass_3, method_name: "c_method", method_type: "ClassMethod"}
        let(:called_klass_1) { A }
        let(:called_klass_2) { B }
        let(:called_klass_3) { A }


        subject do
          described_class.new(call_sites, 1)
        end

        describe "#query" do
          it do
            expect(strip_whitespace subject.query).to eq strip_whitespace(<<~QUERY)
              MERGE ( k0:Class { name: {klass0} })
              MERGE ( k1:Class { name: {klass1} })
              MERGE

              (
                k0
              )

              - [:OWNS] ->

              (
                m0 :Method {
                  type: {method_type0},
                  name: {method_name0},
                  file: {file0},
                  line_number: {method_definition_line0}}
              )

              MERGE

              (m0)

              -[:CONTAINS]->

              (cs0:CallSite {file: {file0}, line_number: {line_number0}})

              CREATE (e:CallStack)

              MERGE (e)
                -
                [:STEP {number: {step_number0}}]
                ->
              (cs0)

              MERGE

              (
                k1
              )

              - [:OWNS] ->

              (
                m1 :Method {
                  type: {method_type1},
                  name: {method_name1},
                  file: {file1},
                  line_number: {method_definition_line1}}
              )

              MERGE

              (m1)

              -[:CONTAINS]->

              (cs1:CallSite {file: {file1}, line_number: {line_number1}})



              MERGE (e)
                -
                [:STEP {number: {step_number1}}]
                ->
              (cs1)

              MERGE

              (
                k0
              )

              - [:OWNS] ->

              (
                m2 :Method {
                  type: {method_type2},
                  name: {method_name2},
                  file: {file2},
                  line_number: {method_definition_line2}}
              )

              MERGE

              (m2)

              -[:CONTAINS]->

              (cs2:CallSite {file: {file2}, line_number: {line_number2}})



              MERGE (e)
                -
                [:STEP {number: {step_number2}}]
                ->
              (cs2)

            QUERY
          end

          context "with all the same container classes" do
            let(:container_klass_1) { A }
            let(:container_klass_2) { A }
            let(:container_klass_3) { A }


            it do
              expect(strip_whitespace subject.query).to eq strip_whitespace(<<~QUERY)
                MERGE ( k0:Class { name: {klass0} })

                MERGE

                (
                  k0
                )

                - [:OWNS] ->

                (
                  m0 :Method {
                    type: {method_type0},
                    name: {method_name0},
                    file: {file0},
                    line_number: {method_definition_line0}}
                )

                MERGE

                (m0)

                -[:CONTAINS]->

                (cs0:CallSite {file: {file0}, line_number: {line_number0}})

                CREATE (e:CallStack)

                MERGE (e)
                  -
                  [:STEP {number: {step_number0}}]
                  ->
                (cs0)

                MERGE

                (
                  k0
                )

                - [:OWNS] ->

                (
                  m1 :Method {
                    type: {method_type1},
                    name: {method_name1},
                    file: {file1},
                    line_number: {method_definition_line1}}
                )

                MERGE

                (m1)

                -[:CONTAINS]->

                (cs1:CallSite {file: {file1}, line_number: {line_number1}})



                MERGE (e)
                  -
                  [:STEP {number: {step_number1}}]
                  ->
                (cs1)

                MERGE

                (
                  k0
                )

                - [:OWNS] ->

                (
                  m2 :Method {
                    type: {method_type2},
                    name: {method_name2},
                    file: {file2},
                    line_number: {method_definition_line2}}
                )

                MERGE

                (m2)

                -[:CONTAINS]->

                (cs2:CallSite {file: {file2}, line_number: {line_number2}})



                MERGE (e)
                  -
                  [:STEP {number: {step_number2}}]
                  ->
                (cs2)

              QUERY
            end
          end
        end

        describe "#params" do
          it do
            expect(subject.params).to eq({
              "execution_count0" => 1,
              "execution_count1" => 1,
              "execution_count2" => 1,
              "file0" => "file_cs1",
              "file1" => "file_cs2",
              "file2" => "file_cs3",
              "klass0" => "A",
              "klass1" => "B",
              "line_number0" => 4,
              "line_number1" => 5,
              "line_number2" => 6,
              "method_definition_line0" => 1,
              "method_definition_line1" => 2,
              "method_definition_line2" => 3,
              "method_name0" => "some_method",
              "method_name1" => "another_method",
              "method_name2" => "yet_another_method",
              "method_type0" => "ClassMethod",
              "method_type1" => "InstanceMethod",
              "method_type2" => "ClassMethod",
              "step_number0" => 1,
              "step_number1" => 2,
              "step_number2" => 3,
            })
          end
        end
      end
    end
  end
end
