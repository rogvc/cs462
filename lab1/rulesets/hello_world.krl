ruleset hello_world {
  meta {
    name "Hello World"
    description << 
    A first ruleset for the Quickstart Pico guide.
    >>
    author "Phil Windley (gracefully copied by Rogerio Cruz)"
    shares hello
  }

  global  {
    hello = function(obj) {
      msg = "Hello " + obj;
      msg
    }
  }

  rule hello_world {
    select when echo hello
    send_directive("say", {"something": "Hello World"})
  }

  rule hello_monkey {
    select when echo monkey
    pre {
      // Using || operator:
      // name = event:attrs{"name"}.klog("This person said hello: ") || "Monkey".klog("This person said hello: ")

      // Using ternary conditional:
      name = (event:attrs{"name"}) => event:attrs{"name"}.klog("This person said hello: ") | "Monkey".klog("This person said hello: ")
    }

    send_directive("say", {"something": "Hello " + name})
  }

}