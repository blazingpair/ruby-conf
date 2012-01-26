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
    it "returns a config" do
      config = subject.define "config" do
        something "hi"
      end
      config.something.should == "hi"
    end
    it "can be chained" do
      subject.define "config", :as => :MyConfig do
        love_song (RubyConf.define "love_song" do
          title "in me all along"
        end)
      end
      MyConfig.love_song.title.should == 'in me all along'
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
