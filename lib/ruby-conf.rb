#
#
# @author Hollin Wilkins & Curtis Schofield
class RubyConf
  @@configs = {}

  class Config
    attr_reader :attributes

    def initialize
      @attributes = {}
    end

    def [](name)
      value = @attributes[name.to_sym]

      if value.is_a?(Proc)
        value.call
      else
        value
      end
    end

    def []=(name,value)
      @attributes[name.to_sym] = value
    end

    def inherit(name, parent)
      self[name] = Config.new
      self[name].attributes.merge! parent.attributes.clone
    end

    def method_missing(name, *args, &block)
      if block_given?
        _inherit(name, args)
        _set_config_with_block(name,block)
        return
      end

      super if 0 == args.size && !@attributes.has_key?(name.to_sym)

      _set_or_get_attribute(name, args)
    end

    def respond_to?(name)
      if @attributes.has_key? name.to_sym
        true
      elsif @parent
        @parent.respond_to?(name)
      else
        super
      end
    end

    private

    def _set_or_get_attribute(name, args)
      case(args.size)
      when 0:
        # config.something 
        # => 'value' 
        self[name]
      when 1:
        # config.something "value"
        self[name] = args.first
      else
        # config.something "value", "value2"
        self[name] = args
      end
    end

    def _update_config_with_block(name,block)
      self[name].instance_eval(&block)
    end

    def _new_config_with_block(name, block)
      self[name] = RubyConf.define(&block)
    end

    def _set_config_with_block(name, block)
      if self[name].is_a?(Config)
        _update_config_with_block(name,block)
      else
        _new_config_with_block(name,block)
      end
    end

    def _inherit(name, args)
      if args.size > 0 && args.first.is_a?(Hash) && args.first.has_key?(:inherits)
        inherit name, args.first[:inherits]
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

  def self.[](name)
    @@configs[name.to_sym]
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
