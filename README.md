# Maw

🔥 A DSL for the DragonRuby Game Toolkit.

### What is a DSL?

A DSL is a "domain-specific language": code that lets you express
something more effectively, clearly or concisely.

## OK, so what does Maw do?

### It lets you type less

Maw is designed to save time by **eliminating the need to refer
to `args`**, or pass it around your code.

A Maw program starts with `Maw!`, which activates Maw's `Ergonomic`
and `Helpers` modules on the top-level object.

If this sounds like gobbledygook, don't worry.

In short, Maw! makes everything from `solids`, `labels`, `sounds`, `outputs`, `keyboard`, `mouse`, `primitives`, `easing`,
`grid`, to `tick_count` available **just as they've been written here**.

So you'll never have to type `args` again!

### Plug-and-play controls

Maw offers **Controls** which lets you map keyboard, mouse and controller binds to action names, then check their state in a convenient way:

```ruby
controls.define :quit, keyboard: :q
controls.define :debug, keyboard: :back_slash if development?
controls.define :attack, keyboard: :e, mouse: :button_left, controller_one: :x
```

Once you have defined `:attack`, now you can check e.g. `controls.my_action?`, `controls.my_action_down?`, `controls.my_action_held?`, `controls.my_action_up?`, `controls.my_action_latch?`.

Checking the state of a control which hasn't been defined is considered normal.

**Controls** will create a stub (with no inputs bound), then:
  - In development, log to help you discover and bind the action.
  - In production,  do nothing, assuming you have intentionally disabled it.

Therefore in production, code which checks `controls.debug?` as defined above will simply receive _`false`_.

### Helpers

Maw also offers a couple of helper methods, for example `desktop?`, `development?` (`dev?`), `production?` (`prod?`).

A prominent helper is `controls`, which lets you define global controls without any ceremony:

```ruby
Maw!

controls do
  define :quit, keyboard: :q
  define :jump, keyboard: :space
end

tick {
    exit if controls.quit?
    
    if controls.jump?
    end
    
    # This won't break the game, but will log to the console in dev
    # so you can prototype more quickly
    if controls.some_new_action?
    end
}
```

## Using Maw

I recommend cloning, forking or downloading the [MawStarter](https://github.com/togetherbeer/MawStarter) project to get started.

If you are using [Smaug](https://smaug.dev), you can "smaug run" inside the directory to run the game.

Don't forget to rename it to `YourAwesomeProject` first!

Otherwise, it can run like a regular DragonRuby project from inside `dragonruby-folder/mygame`.

### Existing Project (Smaug)

To use Maw in an existing Smaug project, do **`smaug add maw`**.

Next, ensure your main.rb loads `smaug.rb` before any of your game code, e.g.:

```ruby
require 'smaug.rb'
require 'app/requires.rb' # recommended place for any other requires (optional)
require 'app/game.rb'     # placing this last ensures deps load before game code
```

If you have any game code in `main.rb` already: move it to `game.rb`, cut and paste
its requires into `app/requires.rb` then create a `main.rb` similar to the above in its place.

Then, add `Maw!` to the top of your `app/game.rb`

Your game should work as normal! But now you can get to work ~~purging~~ ~~dropping~~ annihilating every little `args` and `args.outputs.` in sight :-)

### Existing Project (other)

To use Maw in an existing non-Smaug DragonRuby project, ~~first install Smaug~~ (_I'm kidding, but it would be your friend_ :-)...

**Just copy `lib/maw.rb` into your game directory**, then require it before your game code.

To do this, you might like to rename main.rb to `game.rb`, then put the following in main.rb's place:

```ruby
require 'lib/maw.rb'
require 'app/game.rb'
```

Next, add `Maw!` to the top of app/game.rb. Your game should work as normal!

Now you can simplify your game code, dropping the need for `args`.

## How can I simplify my code using Maw?

Simply update any references to `args.outputs.foo` to `foo`, `args.bar` to `bar`.

And delete any args parameters. For example

```ruby
def render_player(args)
  args.outputs.sprites << { ... }
end

# can become

def render_player
  sprites << { ... }
end
```

### Tick

Maw comes with a simple **tick/init** mechanism which offers a couple of
benefits:

1. It does not need to receive args 🙃
2. It is block based, and lets you express your init and tick in a way that stands out from other code.
3. Pass a block to `init` to define logic that will execute on first tick, on reset, and any time you call `init` without a block in the future.
4. It offers this while being fully optional and backwards compatible with regular DR code!

```ruby
Maw!

controls.define :reset, keyboard: :r

init {
    $state.background = [grid.rect, rand(255), rand(255), rand(255)]
}

tick {
    init if controls.reset_down?
    solids << $state.background
}
```

### Support

If you have any questions about using Maw, message mooff on the DragonRuby GTK Discord and I'll be happy to help.

### License

Maw is licensed under the AGPLv3. A copy of the license is available
in the root of the repository. If you find Maw useful and would like to
deploy it in a closed source game, please contact **mooff** on Discord
for a link to a pay-what-you-want donation page, and a lifetime exemption :-)

❤️‍🔥
