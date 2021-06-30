# Maw DSL for DragonRuby
# https://github.com/togetherbeer/maw
#
# @copyright 2021 mooff <mooff@@together.beer>
# @version 1.3.2
# @license AGPLv3

$outputs = $args.outputs

def Maw!
  extend Maw::Tick

  include Maw
  include Maw::Init
  include Maw::Ergonomic
  include Maw::Helpers
end

def ergonomic!
  include Maw::Ergonomic
end

module Maw
  def maw?; true; end

  module Init
    def init &blk
      if blk
        @init = blk
      else
        @init&.call
      end
    end
  end

  module Tick
    def tick args=nil, &blk
      if blk
        @tick = blk
      else
        if ::Maw::Init === self and !$state.did_maw_init
          $state.did_maw_init = true
          init
        end
        if @time_ticks
          start = Time.now
          result = @tick&.call

          @tick_times[(@tick_times_i += 1) % @tick_time_history_count] = Time.now - start

          if @tick_time_log and $args.tick_count % (60*5) == 0
            total = 0
            for time in @tick_times
              total += time
            end
            average = total / @tick_times.size
            log_info "[Maw] Average tick time: #{'%.2f' % (average*1000)} ms"
          end
        else
          @tick&.call
        end
      end
    end

    def time_ticks! opts={}
      @time_ticks = (opts[:enable] != false)
      @tick_times = []
      @tick_time_history_count = opts[:history] || 64
      @tick_time_log = opts[:log] != false
    end
  end

  module Ergonomic
    class << self
      def included(base)
        @setup ||= setup!
      end

      alias :extended :included
      
      def activate(base=$top_level)
        base.include self
      end

      def setup!
        $args.methods(false).each do |name|
          next if name.to_s.end_with? '='
          next if Kernel.respond_to? name

          eval "
            module ::Maw::Ergonomic
              private def #{name}
                $args.#{name}
              end
            end"
        end
        true
      end
    end

    def args
      $args
    end

    def tick_count
      Kernel.tick_count
    end

    def controls &blk
      $default_controls ||= ::Maw::Controls.new
      $default_controls.instance_eval(&blk) if blk
      $default_controls
    end
  end

  Ergonomics = Ergonomic # to be even more ergonomic

  module Helpers
    def background! color=[0,0,0]
      $outputs.background_color = color
    end

    def sounds
      $outputs.sounds
    end
  end

  class Controls
    attr_accessor :name
    
    @@i = 0    
    def initialize name="Control Set #{@@i+=1}", &blk
      @name = name

      instance_exec(&blk) if blk
      self
    end

    def to_s; "[#{name}]"; end

    def is? state, device, key
      if device == :mouse # mouse doesn't support state qualifiers like .key_down, .key_held etc
        $args.inputs.mouse.send(key)
      else
        $args.inputs.send(device).send(state).send(key)
      end
    end

    def any? state, map
      map.any? do |(device, keys)|
        keys.any? { |key| is? state, device, key }
      end
    end

    def define action, map
      map = normalize map

      define_down action, map
      define_held action, map
      define_up action, map
      define_active action, map
    end

    alias :action :define

    private

    def define_down action, map
      [:"#{action}_down", :"#{action}_down?"].each do |name|
        define_singleton_method(name) { any? :key_down, map }
      end
    end

    def define_held action, map
      [:"#{action}_held", :"#{action}_held?"].each do |name|
        define_singleton_method(name) { any? :key_held, map }
      end
    end

    def define_up action, map
      [:"#{action}_up", :"#{action}_up?"].each do |name|
        define_singleton_method(name) { any? :key_up, map }
      end
    end

    def define_active action, map
      [:"#{action}", :"#{action}?"].each do |name|
        define_singleton_method(name) {
          any?(:key_down, map) or any?(:key_held, map)
        }
      end
    end

    def normalize map
      map.map { |(device, keys)| [device, Array(keys)] }.to_h
    end
  end
end
