require 'spec_helper'

module RubyConf
  def self.puts(*args) end
end

describe RubyConf do

  before do
    RubyConf.clear
  end

  subject { RubyConf }

  describe "lambda arguments" do

    it "uses bang to ensure lambdas get called only once" do
      RubyConf.define :Lambang do
        noargs -> { "#{rand(1000)}" }
        bang ->(a, b) { "#{a}-#{b}-#{rand(1000)}" }
      end

      normal = Lambang.noargs
      Lambang.noargs!.should == normal
      Lambang.noargs.should_not == normal

      bang = Lambang.noargs!
      Lambang.noargs!.should == bang

      #reset it by not using bang
      Lambang.noargs.should_not == bang

      bang2 = Lambang.noargs!
      bang2.should_not == bang
      Lambang.noargs!.should == bang2


      normal = Lambang.bang(:a, :b)
      Lambang.bang!(:a, :b).should == normal
      Lambang.bang(:a, :b).should_not == normal

      bangcd = Lambang.bang!(:c, :d)
      bangef = Lambang.bang!(:e, :f)
      Lambang.bang!(:c, :d).should == bangcd
      Lambang.bang!(:e, :f).should == bangef
      Lambang.bang!(:c, :d).should == bangcd

      #reset it by not using bang
      Lambang.bang(:c, :d).should_not == bangcd

      bangcd2 = Lambang.bang!(:c, :d)
      bangcd2.should_not == bangcd
      Lambang.bang!(:c, :d).should == bangcd2
    end

    it "handles hash arguments properly" do
      RubyConf.define :LambdaHashes do
        key ->(options) {
          options
        }
      end

      LambdaHashes.key(hash: "value").should == {hash: "value"}
      LambdaHashes.key("non hash").should == "non hash"
      LambdaHashes.key(["array", "values"]).should == ["array", "values"]

    end

    it "accepts arguments for lambdas" do
      RubyConf.define("lambda args", :as => :Hannibal) do
        silence_of_the lambda { |clarise, fava, chianti|
          "Hello #{clarise}.  I'd like to eat your liver with #{fava} beans, and a nice #{chianti}."
        }
      end

      Hannibal.silence_of_the('Cow', 'refried', 'glass of milk').should == "Hello Cow.  I'd like to eat your liver with refried beans, and a nice glass of milk."

      RubyConf.define("single lambda arg", :as => :Argue) do
        you_are_a lambda { |meanie|
          "Why are you such a jerk, #{meanie}"
        }
      end

      Argue.you_are_a('My Love?').should == "Why are you such a jerk, My Love?"

      RubyConf.define(:LambdaToString) do
        no_args        ->                 { "none" }
        one_arg        ->(arg)            { "one|#{arg.inspect}" }
        var_args       ->(*args)          { "var|#{args.inspect}" }
        multi_args     ->(one,two)        { "multi|#{one.inspect}|#{two.inspect}" }
        multi_var_args ->(one,*two,three) { "multivar|#{one.inspect}|#{two.inspect}|#{three.inspect}" }
      end

      LambdaToString.to_s.should == <<-TOS
[LambdaToString]

multi_args: multi|nil|nil
multi_var_args: multivar|nil|[nil]|nil
no_args: none
one_arg: one|nil
var_args: var|[nil]
      TOS
    end
  end

  describe ".root" do

    it "has a heirarchy" do
      RubyConf.define "RootTest" do
        outer do
          middle do
            inner do
              val value
            end
          end
        end
        inherit do
          val "val"
          ival ->{ self.val }
        end

        other(inherits:inherit) do
          inner do
            value "correct"
          end
          self_refa ->{ self.inner.value }
          self_refb ->{ self.ival }
        end
      end

      other = RootTest.other.detach
      other.val.should == "val"
      other.ival.should == "val"

      other.inner.value.should == "correct"
      other.self_refa.should == "correct"
      other.self_refb.should == "val"

      RootTest.outer.middle.inner.val.should == "value"

      RootTest.__rc_parent.should be_nil
      RootTest.outer.__rc_parent.should == RootTest
      RootTest.outer.middle.__rc_parent.should == RootTest.outer
      RootTest.outer.middle.inner.__rc_parent.should == RootTest.outer.middle

      RootTest.__rc_root.should == RootTest
      RootTest.outer.__rc_root.should == RootTest
      RootTest.outer.middle.__rc_root == RootTest
      RootTest.outer.middle.inner.__rc_root.should == RootTest

      RootTest.outer.detach
      RootTest.outer.__rc_root.should == RootTest.outer
      RootTest.outer.middle.__rc_root == RootTest.outer
      RootTest.outer.middle.inner.__rc_root.should == RootTest.outer

      RootTest.outer.middle.detach
      RootTest.outer.middle.__rc_root == RootTest.outer.middle
      RootTest.outer.middle.inner.__rc_root.should == RootTest.outer.middle

    end

    it "sets self properly in nested procs" do
      RubyConf.define "SelfSetTest" do
        val proc { self }
        outer do
          val proc { self }
          middle do
            val proc { self }
            inner do
              val proc { self }
            end
          end
        end
      end

      SelfSetTest.val.should == SelfSetTest
      SelfSetTest.outer.val.should == SelfSetTest
      SelfSetTest.outer.middle.val.should == SelfSetTest
      SelfSetTest.outer.middle.inner.val.should == SelfSetTest

    end

  end

  describe ".to_s" do

    it "does it's best to print procs but will fail gracefully" do
      RubyConf.define :ProcStrings do
        valid ->{ "valid return" }
        valid_args ->(a, b, c){ "all empty > a:#{a} b:#{b} c:#{c} <" }
        broken ->{ raise "oops" }
        broken_args ->(a, b, c){ raise "oops: a:#{a} b:#{b} c:#{c} <" }
        self_referential ->{self}
        recursive_to_s ->{self.to_s.split("\n").join(" ")}
        recursive_inspect ->{self.inspect}
      end

      tos = <<-STR
[ProcStrings]

broken: [UNRESOLVED]
broken_args: [UNRESOLVED]
recursive_inspect: [ProcStrings] broken: "[UNRESOLVED:oops]", broken_args: "[UNRESOLVED:oops: a: b: c: <]", recursive_inspect: "[RECURSIVE]", recursive_to_s: "[ProcStrings]  broken: [UNRESOLVED] broken_args: [UNRESOLVED] recursive_inspect: [RECURSIVE] recursive_to_s: [RECURSIVE] self_referential: [SELF] valid: valid return valid_args: all empty > a: b: c: <", self_referential: [SELF], valid: "valid return", valid_args: "all empty > a: b: c: <"
recursive_to_s: [ProcStrings]  broken: [UNRESOLVED] broken_args: [UNRESOLVED] recursive_inspect: [ProcStrings] broken: "[UNRESOLVED:oops]", broken_args: "[UNRESOLVED:oops: a: b: c: <]", recursive_inspect: "[RECURSIVE]", recursive_to_s: "[RECURSIVE]", self_referential: [SELF], valid: "valid return", valid_args: "all empty > a: b: c: <" recursive_to_s: [RECURSIVE] self_referential: [SELF] valid: valid return valid_args: all empty > a: b: c: <
self_referential: [SELF]
valid: valid return
valid_args: all empty > a: b: c: <
      STR

      ProcStrings.to_s.should == tos
      ProcStrings.to_str.should == tos
      ProcStrings.inspect.should == "[ProcStrings] broken: \"[UNRESOLVED:oops]\", broken_args: \"[UNRESOLVED:oops: a: b: c: <]\", recursive_inspect: \"[ProcStrings] broken: \\\"[UNRESOLVED:oops]\\\", broken_args: \\\"[UNRESOLVED:oops: a: b: c: <]\\\", recursive_inspect: \\\"[RECURSIVE]\\\", recursive_to_s: \\\"[ProcStrings]  broken: [UNRESOLVED] broken_args: [UNRESOLVED] recursive_inspect: [RECURSIVE] recursive_to_s: [RECURSIVE] self_referential: [SELF] valid: valid return valid_args: all empty > a: b: c: <\\\", self_referential: [SELF], valid: \\\"valid return\\\", valid_args: \\\"all empty > a: b: c: <\\\"\", recursive_to_s: \"[ProcStrings]  broken: [UNRESOLVED] broken_args: [UNRESOLVED] recursive_inspect: [ProcStrings] broken: \\\"[UNRESOLVED:oops]\\\", broken_args: \\\"[UNRESOLVED:oops: a: b: c: <]\\\", recursive_inspect: \\\"[RECURSIVE]\\\", recursive_to_s: \\\"[RECURSIVE]\\\", self_referential: [SELF], valid: \\\"valid return\\\", valid_args: \\\"all empty > a: b: c: <\\\" recursive_to_s: [RECURSIVE] self_referential: [SELF] valid: valid return valid_args: all empty > a: b: c: <\", self_referential: [SELF], valid: \"valid return\", valid_args: \"all empty > a: b: c: <\""
    end

    it "prints out the config in a human readable way" do
      RubyConf.define("some shapes", :as => :Shapes) {
        defaults { position { px 10; py 20 }; size { width 100; height 200 }; rotation lambda { '90 degrees' } }
        other { sides 4; color blue like the color of the sea before a storm }
        triangle(:inherits => 'defaults') { named :rectangle; size { width 5 }; rotation '180 degrees' }
        square(:inherits => defaults) { named :rectangle; size { width 50 } }
        circle(:inherits => [:defaults, :other]) { sides 0; rotation lambda { 'who could possibly tell?' }; fits { pegs { round lambda { "yes" }; square lambda { "no" } } } }
        polygon { sides 'many'; details { named 'somename'; actual_sides 100; discussion { seems? 'like a lot of damn sides' } } }
        dafuq? { holy fuck this is some god damn evil fucking black sorcery!; how the hell did he make this happen?; mason is some kind of sorcerer; this is freaking me out man; srsly dude }
      }

      Shapes.inspect.should == '[some shapes] circle: { color: "blue like the color of the sea before a storm", fits: { pegs: { round: "yes", square: "no" } }, position: { px: 10, py: 20 }, rotation: "who could possibly tell?", sides: 0, size: { height: 200, width: 100 } }, dafuq: { holy: "fuck this is some god damn evil fucking black sorcery", how: "the hell did he make this happen", mason: "is some kind of sorcerer", srsly: "dude", this: "is freaking me out man" }, defaults: { position: { px: 10, py: 20 }, rotation: "90 degrees", size: { height: 200, width: 100 } }, other: { color: "blue like the color of the sea before a storm", sides: 4 }, polygon: { details: { actual_sides: 100, discussion: { seems: "like a lot of damn sides" }, named: "somename" }, sides: "many" }, square: { named: :rectangle, position: { px: 10, py: 20 }, rotation: "90 degrees", size: { height: 200, width: 50 } }, triangle: { named: :rectangle, position: { px: 10, py: 20 }, rotation: "180 degrees", size: { height: 200, width: 5 } }'
      Shapes.to_s.should == <<-TEXT
[some shapes]

circle:
  color: blue like the color of the sea before a storm
  fits:
    pegs:
      round: yes
      square: no
  position:
    px: 10
    py: 20
  rotation: who could possibly tell?
  sides: 0
  size:
    height: 200
    width: 100
dafuq:
  holy: fuck this is some god damn evil fucking black sorcery
  how: the hell did he make this happen
  mason: is some kind of sorcerer
  srsly: dude
  this: is freaking me out man
defaults:
  position:
    px: 10
    py: 20
  rotation: 90 degrees
  size:
    height: 200
    width: 100
other:
  color: blue like the color of the sea before a storm
  sides: 4
polygon:
  details:
    actual_sides: 100
    discussion:
      seems: like a lot of damn sides
    named: somename
  sides: many
square:
  named: rectangle
  position:
    px: 10
    py: 20
  rotation: 90 degrees
  size:
    height: 200
    width: 50
triangle:
  named: rectangle
  position:
    px: 10
    py: 20
  rotation: 180 degrees
  size:
    height: 200
    width: 5
TEXT
    end

  end
   
  describe ".define" do
    context "no arguments" do
      it "returns anonymous config" do
        config = subject.define do
          equality true
        end
        config.equality.should be_true
      end
    end
    context ":inherit" do
      let(:inherited_config) do 
        RubyConf.define "inherited_config" do
          basic do
            movie "b"
            thing do
              origin "swamp"
              type "monster"
            end
          end

          laboritory :inherits => basic do
            thing do
              strong true
            end
          end

          city :inherits => basic do
            thing do
              origin "ocean"
              name "bob"
            end
          end

          chained :inherits => city do
            thing do
              origin "space"
            end
          end
        end
      end
      it "pre-loads a config with a existing config" do
        inherited_config.laboritory.thing.origin.should == inherited_config.basic.thing.origin
      end
      it "chains inherited configs" do
        inherited_config.chained.movie.should == "b"
        inherited_config.chained.thing.origin.should == "space"
        inherited_config.chained.thing.name.should == "bob"
      end
      it "does not overwrite values" do
        inherited_config.city.thing.origin.should == "ocean"
      end
    end

    context ":as" do 
      it "creates a global Constant" do
        subject.define "rails_database", :as => :RailsDatabase do
          production :host => 'localhost', :password => 'cake', :username => 'eggs2legit'
        end
        ::RailsDatabase.production[:host].should == 'localhost'
        ::RailsDatabase.production[:username].should_not be_nil
        ::RailsDatabase.production[:password].should_not be_nil
      end
    end

    it "can reopen configs" do
      config = subject.define do
        godzilla do
          spines false
          awesome true
        end
      end
      config.godzilla do
        spines true
      end
      config.godzilla.spines.should == true
      config.godzilla.awesome.should == true
    end

    it "returns a named config" do
      config = subject.define "a_name" do
        something "hi"
      end
      config.something.should == "hi"
      subject.a_name.something.should == 'hi'
    end

    it "can be chained" do
      subject.define "config", :as => :ChainedConfig do
        love_song (RubyConf.define "love_song" do
          title "in me all along"
        end)
      end
      ChainedConfig.love_song.title.should == 'in me all along'
    end

    it "can be chained using do blocks instead of RubyConf.define" do
      subject.define "config", :as => :MyConfig do
        turtles do
          teenage true
          mutant true
          ninja true

          raphael do
            mask "red"
          end
        end
      end
      MyConfig.turtles.mutant.should == true
      MyConfig.turtles.raphael.mask.should == "red"
    end

    describe "RubyConf" do
      it "can access configs using square brackets" do
        subject.define "config" do
          shredder "villain"
        end
        subject[:config].shredder.should == "villain"
      end
    end
    describe "RubyConf::Config" do
      it "can access attributes using square brackets" do
        subject.define "config" do
          splinter "the man"
        end
        subject[:config][:splinter].should == "the man"
      end
    end
    it "defines a new configuration with a given name" do
      subject.define "thing" do end
      subject.should respond_to(:thing)
    end
    it "sets a variable in new configuration with a given name to a value" do
      subject.define "thing" do
        honky true
      end
      subject.thing.honky.should be_true
    end
    describe "namespace with attribute with lambda arg" do
      before do
        subject.define 'with_llama' do
          get_wool lambda {
            @shear_count = @shear_count.to_i + 1
          }
        end
      end
      it "should return the value of lambda" do
        subject.with_llama.get_wool.should == 1
      end
      it "should return the value of lambda dynamicly" do
        subject.with_llama.get_wool.should == 1
        subject.with_llama.get_wool.should == 2
        subject.with_llama.get_wool.should == 3
      end
    end
    describe "namespace with attribute with extra args" do
      before do
        subject.define "namespace" do
          attribute "hello", "tiny" , "tim"
        end
      end
      it "sets an array" do
        subject.namespace.attribute.should == %w(hello tiny tim)
      end
    end
    describe "namespaced to 'cake' with flour and water" do
      before do
        subject.define "cake" do
          flour     "1 cup"
          water     "1/3 cup"
          skim_milk "2/3 cup"
        end
      end
      it "cake has 1 cup of flour" do
        subject.cake.flour.should == '1 cup'
      end
      it "cake has 1 cup of water" do
        subject.cake.water.should == '1/3 cup'
      end
      it "responds to skim_milk" do
        subject.cake.should respond_to(:skim_milk)
      end
      it "can indicate the presence of an attribute when ending in ? and raises error for !" do
        subject.cake.bees.should == nil
        subject.cake.flour?.should be_true
        subject.cake.bees?.should be_false

        lambda do
          subject.cake.bees!
        end.should raise_error NameError

      end
    end
  end

  describe "Automatically sets the RUBY_CONF variable" do

    after do
      dir = Dir["./**/test_conf.rb.tmpl"].first[/^(.*?)\/test_conf.rb.tmpl$/, 1]
      File.delete("#{dir}/test_conf.rc") if File.exists?("#{dir}/test_conf.rc")
    end

    it "will autoload the first ruby-conf that it can find if none is provided" do

      dir = Dir["./**/test_conf.rb.tmpl"].first[/^(.*?)\/test_conf.rb.tmpl$/, 1]

      val = Random.rand.to_s
      File.write("#{dir}/test_conf.rc", File.read("#{dir}/test_conf.rb.tmpl").gsub('{{VALUE}}', val))

      RUBY_CONF.should be_nil
      RUBY_CONF.ident.should == "FOUND AND LOADED BASIC CONFIG #{val}"
      loaded = RUBY_CONF.__rc_loaded_conf

      FileUtils.touch(loaded[:path], mtime: 100)
      File.mtime(loaded[:path]).to_i.should_not == loaded[:mtime]
      RUBY_CONF.ident.should == "FOUND AND LOADED BASIC CONFIG #{val}"
      RUBY_CONF.__rc_loaded_conf[:mtime].should == loaded[:mtime]

      val = Random.rand.to_s
      File.write("#{dir}/test_conf.rc", File.read("#{dir}/test_conf.rb.tmpl").gsub('{{VALUE}}', val))
      FileUtils.touch(loaded[:path], mtime: 100)
      RUBY_CONF.ident.should == "FOUND AND LOADED BASIC CONFIG #{val}"
      RUBY_CONF.__rc_loaded_conf[:mtime].should_not == loaded[:mtime]

      RubyConf.clear
      module ::Rails
        def self.env() "foo" end
      end
      ::Object.const_defined?(:Rails).should be_true
      RUBY_CONF.should be_nil
      RUBY_CONF.ident.should == "FOUND AND LOADED RAILS ENV CONFIG #{val}"

      RubyConf.clear
      module ::Rails
        def self.env() "bar" end
      end
      ::Object.const_defined?(:Rails).should be_true
      RUBY_CONF.should be_nil
      RUBY_CONF.ident.should == "FOUND AND LOADED BASIC CONFIG #{val}"

    end

    it "sets the first unnamed config as default" do
      RUBY_CONF.should be_nil
      first = RubyConf.define { ident "first" }
      RUBY_CONF.should_not be_nil
      second = RubyConf.define { ident "second" }
      RUBY_CONF.__rc_conf.should == first
      RUBY_CONF.ident.should == "first"
    end

    it "sets the proper config based on Rails environment and detaches, if it exists" do
      module ::Rails
        def self.env() "foo" end
      end
      ::Object.const_defined?(:Rails).should be_true

      RUBY_CONF.should be_nil
      RubyConf.define do
        foo { ident "correct" }
        bar { ident "wrong" }
      end
      RUBY_CONF.ident.should == "correct"
      RUBY_CONF.__rc_parent.should be_nil

      RubyConf.clear
      RUBY_CONF.should be_nil
      RubyConf.define do
        foo_conf { ident "correct" }
        bar_conf { ident "wrong" }
      end
      RUBY_CONF.ident.should == "correct"

      RubyConf.clear
      RUBY_CONF.should be_nil
      RubyConf.define do
        foo_config { ident "correct" }
        bar_config { ident "wrong" }
      end
      RUBY_CONF.ident.should == "correct"

      RubyConf.clear
      RUBY_CONF.should be_nil
      RubyConf.define do
        ident "correct"
      end
      RUBY_CONF.ident.should == "correct"
    end
  end
end
