# Maw DSL for DragonRuby
# https://github.com/togetherbeer/maw
#
# @copyright 2021 mooff <mooff@@together.beer>
# @version 1.3.9
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

          if @tick_time_log and $args.tick_count % (@tick_time_log_interval) == 0
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
      @tick_time_log_interval = opts[:log_interval] || 60*5 # log every this number of frames
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

    private def args
      $args
    end

    private def tick_count
      Kernel.tick_count
    end

    private def controls &blk
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

    PRODUCTION = $gtk.production

    def prod?; PRODUCTION; end
    def dev?; !PRODUCTION; end

    alias :production? :prod?
    alias :development? :dev?

    DESKTOP_PLATFORMS = ['Windows', 'Linux', 'Mac'].freeze

    def desktop?
      DESKTOP_PLATFORMS.include? $gtk.platform
    end

    instance_methods(false).each do |method|
      private method
    end
  end

  class Controls
    @@i = 0
    def self.next_name
      "Control Set #{@@i+=1}"
    end

    attr_accessor :name
    
    def initialize name=nil, &blk
      @name = name || Controls.next_name
      @latch = {}

      instance_exec(&blk) if blk
      self
    end

    def to_s; "[#{name}]"; end

    def is? state, device, key
      case device
      when :mouse
        # mouse doesn't support state qualifiers .key_down, .key_held etc
        $args.inputs.mouse.send(key)
      when :controller_three
        # controller_three is not aliased under inputs, but
        # we can make it work
        $args.inputs.controllers[2]&.send(state)&.send(key)
      when :controller_four
        # same deal here
        $args.inputs.controllers[3]&.send(state)&.send(key)
      else
        # this is the normal path
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
      define_latch action, map
      define_held action, map
      define_up action, map
      define_active action, map
    end

    alias :action :define

    def stub action
      define action, {}
    end

    def method_missing name, *args, &blk
      action = method_name_to_action name
      if !$gtk.production
        log_info "#{to_s} Defining stub for #{action} due to .#{name} being called."
        log_info "#{to_s} You can hook it up like:"
        log_info "#{to_s}   controls.define :#{action}, keyboard: :e, controller_one: :b"
      end
      stub action
      send action
    end

    def method_name_to_action name
      name = name.to_s.sub('?', '')
      for suffix in ['_down', '_held', '_up', '_latch']
        if name.end_with?(suffix)
          name = name[0..name.rindex(suffix)-1]
        end
      end
      name.to_sym
    end

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

    def define_latch action, map
      [:"#{action}_latch", :"#{action}_latch?"].each do |name|
        define_singleton_method(name) {
          if any?(:key_down, map)
            @latch[action] = !@latch[action]
          else
            @latch[action]
          end
        }
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
