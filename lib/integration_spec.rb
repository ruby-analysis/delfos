# frozen_string_literal: true
require "delfos"
require "delfos/neo4j"

describe "integration" do
  context "with a customer call_stack_logger" do
    let(:loading_code) do
      lambda do
        load "fixtures/b.rb"
        load "fixtures/a.rb"
        A.new.some_method
        B.new.another_method anything
      end
    end
    let(:logger) { double "call stack logger", log: nil, save_call_stack: nil }

    before do
      WebMock.disable_net_connect! allow_localhost: false

      Delfos.setup!(
        application_directories: ["fixtures"],
        call_site_logger: logger,
      )
    end

    after do
      WebMock.disable_net_connect! allow_localhost: true
    end

    it "doesn't hit the network" do
      expect(loading_code).not_to raise_error
    end

    it "logs the call sites" do
      expect(logger).to receive(:log) do |parameters, call_site, called_code|
        expect(parameters)  .to be_a Delfos::MethodLogging::MethodParameters
        expect(call_site)   .to be_a Delfos::MethodLogging::CodeLocation
        expect(called_code) .to be_a Delfos::MethodLogging::CodeLocation
      end

      loading_code.call
    end

    it "saves the call stack" do
      expect(logger).to receive(:save_call_stack) do |call_sites, execution_count|
        expect(call_sites)  .to be_a Array
        expect(call_sites.length) .to eq 11
        expect(execution_count) .to eq 1
      end
      loading_code.call
    end
  end

  context "with default neo4j logging" do
    let(:result) do
      Delfos::Neo4j.flush!
      Delfos::Neo4j.execute_sync(query).first
    end

    before(:each) do
      wipe_db!

      Delfos.setup!(application_directories: ["fixtures"])
    end

    after do
      Delfos.reset!
    end

    context "with a and b fixture files" do
      before(:each) do
        load "fixtures/a.rb"
        load "fixtures/b.rb"

        a = A.new
        b = B.new
        a.some_method(1, "", a, something: b)
        Delfos::Neo4j.flush!
      end

      context "recording call stacks" do
        let(:query) do
          <<-QUERY
           MATCH (e:CallStack) - [:STEP{number: 1}] -> (:CallSite) -[:CALLS]->(:Method)<-[:OWNS]-(:Class{name:"B"})
           MATCH (e)           - [:STEP{number: 2}] -> (:CallSite) -[:CALLS]->(:Method)<-[:OWNS]-(:Class{name:"A"})
           MATCH (e2:CallStack)- [:STEP{number: 1}] -> (:CallSite) -[:CALLS]->(:Method)<-[:OWNS]-(:Class{name:"C"})
           RETURN count(e), count(e2)
          QUERY
        end

        it do
          e_count, e2_count = result

          expect(e_count).to eq 1
          expect(e2_count).to eq 1
        end
      end

      context "records arguments" do
        let(:query) do
          <<-QUERY
          MATCH (:CallSite)-[arg:ARG]->(a:Class{name: "A"})

          RETURN count(arg)
          QUERY
        end

        it do
          arg_count = result.first

          expect(arg_count).to eq 1
        end
      end

      context "records call sites" do
        let(:query) do
          <<-QUERY
        MATCH (b:Class{name: "B"})  -  [:OWNS]
          ->  (mb:Method{type: "InstanceMethod", name: "another_method"})
          -[:CONTAINS]->(csB2C:CallSite)-[:CALLS]->(mc)

        MATCH (a:Class{name: "A"})  -  [:OWNS]
          -> (ma:Method{name: "some_method"}) -[:CONTAINS]
          ->(csA2B:CallSite)-[:CALLS]
          ->(mb)

        MATCH (ma)-[:CONTAINS]
          ->(csA2C:CallSite)
          -[:CALLS]
          -> (mc:Method{type: "InstanceMethod", name: "method_with_no_more_method_calls"})
          <- [:OWNS] - (c:Class{name: "C"})

        RETURN
          count(csA2B),
          count(csB2C),
          count(csA2C)
          QUERY
        end

        it do
          call_site_1_count, call_site_2_count, call_site_3_count =
            result

          expect(call_site_1_count).to eq 1
          expect(call_site_2_count).to eq 1
          expect(call_site_3_count).to eq 1
        end
      end

      context "recording instance methods" do
        let(:query) do
          <<-QUERY
        MATCH (a:Class{name: "A"})  -  [:OWNS]
          -> (ma:Method{type: "InstanceMethod", name: "some_method"})
        MATCH (b:Class{name: "B"})  -  [:OWNS]
          ->  (mb:Method{type: "InstanceMethod", name: "another_method"})
        MATCH (c:Class{name: "C"})  -  [:OWNS]
          ->  (mc:Method{type: "InstanceMethod", name: "method_with_no_more_method_calls"})

        RETURN
          count(ma), ma,
          count(mb), mb,
          count(mc), mc
          QUERY
        end

        it do
          a_method_count, method_a, b_method_count, method_b, c_method_count, method_c = result

          expect(a_method_count).to eq 1

          expect(method_a).to eq("file" => "fixtures/a.rb",
                                 "line_number" => 3,
                                 "name" => "some_method",
                                 "type" => "InstanceMethod")

          expect(b_method_count).to eq 1
          expect(c_method_count).to eq 1
        end
      end
    end

    context "class method calls an instance method" do
      before(:each) do
        load "fixtures/class_method_calls_instance_method.rb"

        ClassMethodCallsAnInstanceMethod.a_class_method

        Delfos::Neo4j.flush!
      end

      let(:query) do
        <<-QUERY
          MATCH (a:Class{name: "ClassMethodCallsAnInstanceMethod"})  -  [:OWNS]
            -> (ma:Method{type: "ClassMethod", name: "a_class_method"})

          MATCH (b:Class{name: "HasInstanceMethod"})  -  [:OWNS]
            ->  (mb:Method{type: "InstanceMethod", name: "an_instance_method"})

          MATCH (ma)-[:CONTAINS]->(cs:CallSite)-[:CALLS]->(mb)

      RETURN
        count(ma), ma,
        count(mb), mb,
        count(cs), cs
        QUERY
      end

      it do
        a_method_count, method_a, b_method_count, method_b, call_site_count, call_site = result

        expect(a_method_count).to eq 1

        expect(method_a).to eq("file" => "fixtures/class_method_calls_instance_method.rb",
                               "line_number" => 2,
                               "name" => "a_class_method",
                               "type" => "ClassMethod")

        expect(b_method_count).to eq 1

        expect(method_b).to eq("file" => "fixtures/class_method_calls_instance_method.rb",
                               "line_number" => 8,
                               "name" => "an_instance_method",
                               "type" => "InstanceMethod")

        expect(call_site_count).to eq 1

        expect(call_site).to eq("file" => "fixtures/class_method_calls_instance_method.rb",
                                "line_number" => 3)
      end
    end

    context "instance method calls a class method" do
      before(:each) do
        load "fixtures/instance_method_calls_class_method.rb"

        InstanceMethodCallsAClassMethod.new.an_instance_method

        Delfos::Neo4j.flush!
      end

      let(:query) do
        <<-QUERY
          MATCH (a:Class{name: "InstanceMethodCallsAClassMethod"})  -  [:OWNS]
            -> (ma:Method{type: "InstanceMethod", name: "an_instance_method"})

          MATCH (b:Class{name: "HasClassMethod"})  -  [:OWNS]
            ->  (mb:Method{type: "ClassMethod", name: "a_class_method"})

          MATCH (ma)-[:CONTAINS]->(cs:CallSite)-[:CALLS]->(mb)

      RETURN
        count(ma), ma,
        count(mb), mb,
        count(cs), cs
        QUERY
      end

      it do
        a_method_count, method_a, b_method_count, method_b, call_site_count, call_site = result

        expect(a_method_count).to eq 1

        expect(method_a).to eq("file" => "fixtures/instance_method_calls_class_method.rb",
                               "line_number" => 2,
                               "name" => "an_instance_method",
                               "type" => "InstanceMethod")

        expect(b_method_count).to eq 1

        expect(method_b).to eq("file" => "fixtures/instance_method_calls_class_method.rb",
                               "line_number" => 8,
                               "name" => "a_class_method",
                               "type" => "ClassMethod")

        expect(call_site_count).to eq 1

        expect(call_site).to eq("file" => "fixtures/instance_method_calls_class_method.rb",
                                "line_number" => 3)
      end
    end

    context "with a call to super inside new" do
      before do
        Object.send(:remove_const, :SomeKlass) if defined? ::SomeKlass
        Object.send(:remove_const, :SomeSubKlass) if defined? ::SomeSubKlass
      end

      context "without Delfos enabled" do
        before do
          load "./fixtures/sub_classes/sub_classes.rb"
        end

        it do
          expect(SomeKlass).to be_a Class
          expect(SomeSubKlass).to be_a Class

          expect(SomeKlass.new).to be_a SomeSubKlass
        end
      end

      context "with Delfos enabled" do
        before do
          Delfos.setup!(application_directories: ["./fixtures/sub_classes"])

          load "./fixtures/sub_classes/sub_classes.rb"
        end

        it do
          expect(SomeKlass).to be_a Class
          expect(SomeSubKlass).to be_a Class

          initialization = lambda do
            expect(SomeKlass.new).to be_a SomeSubKlass
          end

          expect(initialization).not_to raise_error
        end
      end
    end
  end
end
