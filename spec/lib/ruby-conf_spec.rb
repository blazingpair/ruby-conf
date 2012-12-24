require 'spec_helper'
require 'ruby-conf'

describe RubyConf do
  subject { RubyConf }

  describe "lambda arguments" do
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

      LambdaToString.to_s.should == "[LambdaToString]\n\nmulti_args: multi|nil|nil\n\nmulti_var_args: multivar|nil|[nil]|nil\n\nno_args: none\n\none_arg: one|nil\n\nvar_args: var|[nil]\n\n"
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
      end

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
            thing do
              origin "swamp"
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
            end
          end

        end
      end
      it "pre-loads a config with a existing config" do
        inherited_config.laboritory.thing.origin.should == inherited_config.basic.thing.origin
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
end
