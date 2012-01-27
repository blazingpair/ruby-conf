require 'spec_helper'
require 'ruby-conf'

# write it
#
#RubyConf.define "namespace" do
# thingy 'aoeuaoe'
#end
#
## read it
#
#RubyConf.namespace.thingy 


describe RubyConf do
  subject { RubyConf }
   
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
        RubyConf.define do
          basic do
            thing do
              origin "swamp"
            end
          end

          building :inherits => basic do
            yoyo "fireball"
          end

          laboritory :inherits => basic do
            thing do
              strong true
            end 
          end

          city :inherits => basic do
            thing do
              origin "sewer"
            end
          end
        end
      end
      it "pre-loads a config with a existing config" do
        inherited_config.laboritory.thing.origin.should == inherited_config.basic.thing.origin
      end
      it "can be re-declared" do
        inherited_config.city.thing.origin.should == "sewer"
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
      subject.define "config", :as => :MyConfig do
        love_song (RubyConf.define "love_song" do
          title "in me all along"
        end)
      end
      MyConfig.love_song.title.should == 'in me all along'
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
      it "our cake has no bees and raises NameError" do
        lambda do 
          subject.cake.bees
        end.should raise_error NameError
      end
    end
  end
end
