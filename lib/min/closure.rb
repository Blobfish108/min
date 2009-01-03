module Min
  class Closure < Min::Object
    attr_reader   :block, :arguments
    attr_accessor :receiver
    
    def initialize(block, arguments=[])
      @block     = block
      @arguments = arguments
      @receiver  = nil
      
      super Min[:Closure].vtable
    end
    
    def call(context, receiver, *args)
      closure_context = context.create(@receiver)
      
      # inherit receiver from parent context
      bind(closure_context.min_self)
      
      # Special local vars
      closure_context.locals[:it]       = args.first
      closure_context.locals[:self]     = @receiver
      closure_context.locals[:receiver] = receiver
      
      # Pass args as local vars
      bind_params(args).each do |name, value|
        closure_context.locals[name] = value
      end
      
      block.eval(closure_context)
    end
    
    def bind_params(args)
      mapped = {}
      arguments.each_with_index do |argument, i|
        if argument.splat
          # TODO Splat only allowed as last arg for now
          mapped[argument.name] = args[i..-1].to_min
          break
        else
          mapped[argument.name] = args[i] || argument.default
        end
      end
      mapped
    end
    
    def bind(object)
      @receiver = object
      self
    end
    
    def ==(other)
      Closure === other && block == other.block && arguments == other.arguments
    end
    
    def self.bootstrap(runtime)
      vtable = runtime[:Object].vtable.delegated
      
      vtable.add_method(:bind, RubyMethod.new(:bind))
      vtable.add_method(:call, proc { |context, receiver, *args| receiver.call(context, receiver, *args).to_min })
      
      runtime[:Closure] = vtable.allocate
    end
  end
end