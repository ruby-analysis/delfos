# frozen_string_literal: true

module Delfos
  RSpec.describe Config do
    let(:app_path) { expand("app") }
    let(:lib_path) { expand("lib") }

    before do
      expect(subject.included_directories).to eq [app_path, lib_path]
    end

    describe "#include" do
      it "accepts an array of directories" do
        subject.include ["another", "yet_another"]
        expect(subject.included_directories).to include(expand("another"), expand("yet_another"))
      end

      it "ensures uniqueness" do
        subject.include ["another", "another"]
        expect(subject.included_directories).to eq [app_path, lib_path, expand("another")]
      end

      it "appends to the defaults" do
        subject.include "another"
        expect(subject.included_directories).to eq [app_path, lib_path, expand("another")]
      end

      it "accepts individual paths" do
        subject.include "fixtures/a.rb"
        expect(subject.included_files).to eq [expand("fixtures/a.rb")]
      end
    end

    describe "#exclude" do
      it "accepts an array of directories" do
        subject.exclude ["another", "yet_another"]
        expect(subject.excluded_directories).to include(expand("another"), expand("yet_another"))
      end

      it "ensures uniqueness" do
        subject.exclude ["another", "another"]
        expect(subject.excluded_directories).to eq [expand("another")]
      end

      it "accepts individual paths" do
        subject.exclude "fixtures/a.rb"
        expect(subject.excluded_files).to eq [expand("fixtures/a.rb")]
      end
    end

    def expand(p)
      Pathname.new(p).expand_path
    end

    describe "#include=" do
      it "replaces the existing paths" do
        subject.include= "app"

        expect(subject.included_directories).to eq [app_path]
      end
    end

    describe "#exclude=" do
      it "replaces the existing paths" do
        subject.exclude= "app"

        expect(subject.excluded_directories).to eq [app_path]
      end
    end
  end
end



=begin
Delfos.config do |c|
  c.include= ["my-app"] # overwrites the defaults of ["app", "lib"]
  c.include ["app", "lib"] # appends 
  c.include "and_this.rb"
  c.include /this/
  c.include ["some_file.rb"]

  c.include do |file, klass, method_name, class_method|
    klass == Object && method_name == :to_s
  end

  c.exclude= "exclude_only_this"
  c.exclude /that/
  c.exclude RSpec
  c.exclude ["some_other.rb", "another.rb"]
end

Delfos.include?
  config.inclusion.include?

    inclusion = Inclusion.new
    inclusion << AppDirectories.new
    inclusion << AppFiles.new
    inclusion << ->{|f,klass,_,_| klass == Object }

    inclusion.all? do |i|
      i.include?(file, _klass, _method_name)
    end


=end
