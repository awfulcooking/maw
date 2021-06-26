module Maw
    class Controls
      def is? state, device, key
        if device == :mouse # mouse doesn't support state qualifiers like .key_down, .key_held etc
          inputs.mouse.send(key)
        else
          inputs.send(device).send(state).send(key)
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
  