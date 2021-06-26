# Maw DSL for DragonRuby
# https://github.com/togetherbeer/maw
#
# @copyright 2021 mooff <mooff@@together.beer>
# @version 1.1.0
# @license AGPLv3

$args = $gtk.args
$outputs = $args.outputs

def Maw!
  $top_level.include Maw
  $top_level.include Maw::Ergonomic
end

module Maw
  def maw?; true; end

  module Ergonomic
    class << self
      def included(base)
        @setup ||= setup!
      end
      
      def activate(base=$top_level)
        base.include self
      end

      def setup!
        $args.methods(false).each do |name|
          next if name.to_s.end_with? '='
          next if Kernel.respond_to? name

          eval "
            module ::Maw::Ergonomic
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
  end

  Ergonomics = Ergonomic # to be even more ergonomic

  class Controls
    def is? state, device, key
      if device == :mouse # mouse doesn't support state qualifiers like .key_down, .key_held etc
        $inputs.mouse.send(key)
      else
        $inputs.send(device).send(state).send(key)
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
