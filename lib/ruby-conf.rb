#
#
# @author Hollin Wilkins & Curtis Schofield
class RubyConf
  @@configs = {}

  class Config
    def initialize
      @attributes = {}
    end

    def method_missing(name, *args, &block)
      case(args.size)
      when 0:
        if @attributes.has_key? name.to_sym
          value = @attributes[name.to_sym]

          if value.is_a?(Proc)
            value.call
          else
            value
          end
        else
          super
        end
      when 1:
        @attributes[name.to_sym] = args.first
      else
        @attributes[name.to_sym] = args
      end
    end

    def respond_to?(name)
      if @attributes.has_key? name.to_sym
        true
      else
        super
      end
    end
  end
  #  Define a configuration:
  #
  #  RubyConf.define "monkey" , :as => 'MyBonobo' do
  #   has_legs true
  #   number_arms 2
  #   number_legs 2
  #   name 'Nancy Drew'
  #   age 34
  #   number_of_bananas_eaten lambda { 
  #     BanannaChomper.lookup("nancy.bananas").count
  #   }
  #  end
  #
  #
  #  @param [Symbol] namespace of the config
  #  @param [Hash] list of options. e.g. :as => ConstantName 
  def self.define(name = nil , options = {}, &block)
    config = Config.new
    config.instance_eval &block

    @@configs[name.to_sym] = config unless name.nil?
    if options.has_key? :as
      Object.const_set(options[:as].to_s.to_sym, config)
    end
    config
  end

  def self.method_missing(name, *args, &block)
    if @@configs.has_key? name.to_sym
      @@configs[name.to_sym]
    else
      super
    end
  end

  def self.respond_to?(name)
    if @@configs.has_key? name.to_sym
      true
    else
      super
    end
  end
end
