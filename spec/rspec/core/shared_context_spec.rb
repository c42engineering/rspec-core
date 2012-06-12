require "spec_helper"

describe RSpec::SharedContext do
  it "is accessible as RSpec::Core::SharedContext" do
    RSpec::Core::SharedContext
  end

  it "is accessible as RSpec::SharedContext" do
    RSpec::SharedContext
  end

  it "supports before and after hooks" do
    before_all_hook = false
    before_each_hook = false
    after_each_hook = false
    after_all_hook = false
    shared = Module.new do
      extend RSpec::SharedContext
      before(:all) { before_all_hook = true }
      before(:each) { before_each_hook = true }
      after(:each)  { after_each_hook = true }
      after(:all)  { after_all_hook = true }
    end
    group = RSpec::Core::ExampleGroup.describe do
      include shared
      example { }
    end

    group.run

    before_all_hook.should be_true
    before_each_hook.should be_true
    after_each_hook.should be_true
    after_all_hook.should be_true
  end

  it "runs the before each hooks in configuration before those of the shared context" do
    ordered_hooks = []
    RSpec.configure do |c|
      c.before(:each) { ordered_hooks << "config" }
    end

    RSpec.world.shared_context "before each stuff", :example => :before_each_hook_order do
      before(:each) { ordered_hooks << "shared_context"}
    end

    group = RSpec::Core::ExampleGroup.describe :example => :before_each_hook_order do
      before(:each) { ordered_hooks << "example_group" }
      example {}
    end

    group.run

    pending "Issue #632" do
      ordered_hooks.should == ["config", "shared_context", "example_group"]
    end
  end

  it "supports let" do
    shared = Module.new do
      extend RSpec::SharedContext
      let(:foo) { 'foo' }
    end
    group = RSpec::Core::ExampleGroup.describe do
      include shared
    end

    group.new.foo.should eq('foo')
  end

  %w[describe context].each do |method_name|
    it "supports nested example groups using #{method_name}" do
      shared = Module.new do
        extend RSpec::SharedContext
        send(method_name, "nested using describe") do
          example {}
        end
      end
      group = RSpec::Core::ExampleGroup.describe do
        include shared
      end

      group.run

      group.children.length.should eq(1)
      group.children.first.examples.length.should eq(1)
    end
  end
end
