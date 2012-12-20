#
#
# @author Hollin Wilkins & Curtis Schofield & Mason Bo-bay-son
module Magic
  attr_accessor :__rc_chain
  def __rc_gather() "#{to_s}#{__rc_chain.nil? ? "" : " #{__rc_chain.__rc_gather}"}" end
end

class RubyConf < Object
  @@__rc_configs = {}

  class Config
    attr_reader :__rc_attributes, :__rc_parent, :__rc_name, :__rc_chains, :__rc_locked

    def __rc_root() __rc_parent ? __rc_parent.__rc_root : self end

    def initialize(name = nil, parent = nil, &block)
      @__rc_locked, @__rc_attributes, @__rc_chains, @__rc_parent = false, {}, [], parent
      @__rc_name = name.to_sym if name
      instance_eval(&block) if block_given?
      __rc_lock
    end

    def __rc_lock
      @__rc_locked = true
      @__rc_attributes.each_value { |value| value.__rc_lock if value.is_a?(Config) }
      self
    end

    def [](name, args = nil)
      value = @__rc_attributes[name.to_sym]
      value.is_a?(Proc) ? __rc_root.instance_exec(*args, &value) : value
    end

    def __rc_copy(o)
      if o.is_a?(Hash)
        o.inject({}) { |copy, (key, val)| copy[key] = __rc_copy(val); copy }
      elsif o.is_a?(Array)
        o.inject([]) { |copy, i| copy << __rc_copy(i); copy }
      else
        o
      end
    end

    def []=(name, value)
      @__rc_attributes[name.to_sym] = value
    end

    def __rc_set_default(conf, key, value)
      if conf.__rc_attributes.key?(key)
        if value.is_a?(Config)
          sub = conf.__rc_attributes[key]
          value.__rc_attributes.each do |k, v|
            __rc_set_default(sub, k, v)
          end
        end
      else
        conf.__rc_attributes[key] = value
      end
    end

    def method_missing(name, *args, &block)
      name = name.to_sym
      options = args.last.is_a?(Hash) ? args.last : {}

      if block_given?
        if options.key?(:inherits)
          self[name] = [*options[:inherits]].inject(Config.new(name, self, &block)) do |conf, inherited|
            inherited = self[inherited.to_sym] unless inherited.is_a?(Config)
            __rc_copy(inherited.__rc_attributes).each do |key, value|
              __rc_set_default(conf, key, value)
            end
            conf
          end
        elsif self[name].is_a?(Config)
          self[name].instance_eval(&block)
        else
          self[name] = Config.new(name, self, &block)
        end

        while (chain = self[name].__rc_chains.pop)
          self[name][chain] = chain.__rc_chain.nil? ?  "" : chain.__rc_chain.__rc_gather
        end

      else

        super if @__rc_locked && args.size == 0 && !@__rc_attributes.key?(name)

        if !@__rc_attributes.key?(name) && (args.size == 0 || args.first.is_a?(Magic))
          str = name.to_s
          str.extend(Magic)
          if args.first.is_a?(Magic)
            str.__rc_chain = args.first
            @__rc_chains.delete_if { |a| a.equal? args.first }
          end
          @__rc_chains << str
          return str
        end

        if args.empty?
          self[name]
        else
          args = args.size == 1 ? args.first : args
          (@__rc_locked && __rc_attributes[name.to_sym].is_a?(Proc)) ? self[name, args] : self[name] = args
        end

      end

    end

    def respond_to?(name)
      super || @__rc_attributes.key?(name) || @__rc_parent.respond_to?(name)
    end

    def __rc_build_string(depth = 0)
      str = ""
      str += "[#@__rc_name]\n" unless @__rc_parent
      str += "\n"
      @__rc_attributes.keys.map{|k| k.to_s }.sort.each do |key|
        value = self[key]
        str += "  " * depth
        str += "#{key}:"
        str += value.is_a?(Config) ? value.__rc_build_string(depth+1) : " #{value}\n"
        str += "\n" unless depth > 0
      end
      str
    end
    def to_s() __rc_build_string end
    def to_str() to_s end

    def __rc_build_inspect() "#{"[#@__rc_name] " unless @__rc_parent}#{@__rc_attributes.keys.map {|k| k.to_s }.sort.map { |key| "#{key}: #{self[key].is_a?(Config) ? "{ #{self[key].__rc_build_inspect} }" : self[key].inspect}" }.join(", ")}" end
    def inspect() __rc_build_inspect end
  end

  def self.define(name = nil, options = {}, &block)
    config = Config.new(name, &block)
    @@__rc_configs[name.to_sym] = config unless name.nil?

    const = options.fetch(:as, name)
    if const && const.to_s[/^[A-Z]/]
      const = const.to_sym
      Object.const_set(const, config) if !Object.const_defined?(const) || Object.const_get(const).is_a?(Config)
    end
    config
  end

  def self.[](name) @@__rc_configs[name.to_sym] end

  def self.method_missing(name, *args) @@__rc_configs[name.to_sym] end

  def self.respond_to?(name) @@__rc_configs.key?(name.to_sym) end
end
