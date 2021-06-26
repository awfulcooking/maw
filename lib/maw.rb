# Maw DSL for DragonRuby
# https://github.com/togetherbeer/maw
#
# @copyright 2021 mooff <mooff@@together.beer>
# @version 1.2.0
# @license AGPLv3

$args = $gtk.args
$outputs = $args.outputs
$state = $args.state

def Maw!
  extend Maw::Tick

  include Maw
  include Maw::Init
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
        @tick&.call
      end
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
              private
              def #{name}
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

    def controls
      $default_controls ||= ::Maw::Controls.new
    end
  end

  Ergonomics = Ergonomic # to be even more ergonomic

  class Controls
    @@i = 0

    def initialize name="Control Set #{@@i+=1}", &blk
      @name = name

      instance_exec(&blk) if blk
      self
    end

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
