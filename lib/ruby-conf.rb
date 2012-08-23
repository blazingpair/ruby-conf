#
#
# @author Hollin Wilkins & Curtis Schofield & Mason Bo-bay-son
module Magic
  attr_accessor :chain
  def gather() "#{to_s}#{chain.nil? ? "" : " #{chain.gather}"}" end
end

class RubyConf
  @@configs = {}

  class Config
    attr_reader :attributes, :name, :chains, :locked

    def initialize(name = nil)
      @locked = false
      @attributes = {}
      @name = name.to_sym if name
      @chains = []
    end

    def lock
      @locked = true
      @attributes.each_value do |value|
        value.lock if value.respond_to? :lock
      end
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

    def copy_walk(o)
      if o.is_a?(Hash)
        copy = {}
        o.each do |key, val|
          copy[key] = copy_walk(val)
        end
        copy
      elsif o.is_a?(Array)
        copy = []
        o.each do |i|
          copy << copy_walk(i)
        end
        copy
      else
        o
      end
    end

    def inherit(name, parent)
      self[name] = Config.new
      [parent].flatten.each { |p|
        self[name.to_sym].attributes.merge! copy_walk(p.attributes)
      }
    end

    def []=(name,value)
      @attributes[name.to_sym] = value
    end

    def method_missing(name, *args, &block)
      if block_given?
        _inherit(name, args)
        _set_config_with_block(name, block)
        while chain = self[name].chains.pop
          self[name][chain] = chain.chain.nil? ?  "" : chain.chain.gather
        end
        return
      end

      super if @locked && args.size == 0 && !@attributes.has_key?(name.to_sym)
      if !@attributes.has_key?(name.to_sym) && (args.size == 0 || args.first.is_a?(Magic))
        str = name.to_s
        str.extend(Magic)
        if args.first.is_a? Magic
          str.chain = args.first
          @chains.delete_if { |a| a.equal? args.first }
        end
        @chains << str
        return str
      end

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

    def build_s(depth = 0)
      str = ""
      str += "[#@name]\n" if @name
      str += "\n"
      @attributes.keys.map{|k| k.to_s }.sort.each do |key|
        value = self[key]
        str += "  " * depth
        str += "#{key}:"
        str += value.respond_to?(:build_s) ? value.build_s(depth+1) : " #{value}\n"
        str += "\n" unless depth > 0
      end
      str
    end

    def to_s
      build_s
    end

    def to_str
      to_s
    end

    def build_inspect
     "#{"[#@name] " if @name}#{@attributes.keys.map{|k| k.to_s }.sort.map { |key| "#{key}: #{self[key].respond_to?(:build_s) ? "{ #{self[key].build_inspect} }" : "#{self[key].inspect}"}" }.join(", ")}"
    end

    def inspect
      build_inspect
    end

    private

    def _set_or_get_attribute(name, args)
      case(args.size)
      when 0
        # config.something
        # => 'value'
        self[name]
      when 1
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
    config = Config.new(name)
    config.instance_eval &block
    config.lock

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
