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

  def self.define(name, &block)
    @@configs[name.to_sym] = Config.new

    @@configs[name.to_sym].instance_eval &block
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
