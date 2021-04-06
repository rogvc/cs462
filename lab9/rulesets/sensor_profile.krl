ruleset sensor_profile {
  meta {
    use module io.picolabs.wrangler alias wrangler
    use module io.picolabs.subscription alias subs   
    // use module temperature_store alias temps

    shares get_profile, rumor_log, seen_log, latest, processing, state, get_peer
    provides get_profile
  }

  global {
    tags = ["sensor"]
    eventPolicy = {
      "allow": [{"domain": "sensor", "name": "*"}],
      "deny": []
    }
    queryPolicy = {
      "allow": [{"rid": meta:rid, "name": "*"}],
      "deny": []
    }
    get_profile = function () {
      {
        "name": ent:name,
        "location": ent:location,
        "temperature_threshold": ent:temperature_threshold,
        "notification_recipient": ent:notification_recipient 
      }
    }

    rumor_log = function () {
      ent:rumor_log
    }

    seen_log = function () {
      ent:seen_log
    }

    latest = function () {
      ent:latest
    }

    processing = function () {
      ent:processor
    }

    state = function (seen) {
      rumor_log().filter(function(v) 
      {
        id = pid(v{"message_id"})
        seen{id}.isnull() || (seen{id} < sequence(v{"message_id"}))
      }).sort(function(x,y) 
      {
        sequence(x{"message_id"}) <=> sequence(y{"message_id"})
      })
    }

    get_peer = function () {
      s = subs:established("Rx_role", "gossiper")

      in_need = seen_log().filter(function(v,k) 
      {
        state(v).length() > 0
      })

      r = in_need.keys()[random:integer(in_need.length() - 1)]
      in_need.length() < 1 => 
        s[random:integer(s.length() - 1)] 
        | s.filter(function(x) 
          {
            x{"Tx"} == r
          }).head()
    }

    proper_sequence = function (p) {
      fr = rumor_log().filter(function (v)
      {
        id = pid(v{"message_id"})
        id == p
      }).map(function (v) 
      {
        sequence(v{"message_id"})
      })

      fr.sort(function (x,y) 
      {
        x <=> y
      }).reduce(function (x,y) 
      {
        (y == x + 1) => y | x
      }, -1)
    }

    prepare_gossip = function (sub) {
      g = random:integer(10) < 3 => prepare_rumor(sub) | prepare_seen(sub)
      temp = g{"gossip"}.isnull() => prepare_seen(sub) | g
      temp
    }

    prepare_rumor = function (sub) {
      missing = state(seen_log(){sub{"Tx"}})
      response = 
        {
          "gossip": missing.isnull() => null | missing[0],
          "type": "rumor"
        }
      response 
    }

    prepare_seen = function (sub) {
      response = 
        {
          "gossip": latest(),
          "sender": sub,
          "type": "seen"
        }
        response
    }

    sequence = function (mid) {
      mid.split(re#:#).tail().as("Number")
    }

    pid = function (mid) {
      mid.split(re#:#)[0]
    }

    new_rumor = function (temperature) {
      {
        "message_id": wrangler:myself(){"id"} + ":" + ent:my_sequence,
        "sensor_id": wrangler:myself(){"id"},
        "temperature": temperature,
        "timestamp": time:now()
      }
    }


  }

  rule gossip_config {
    select when gossip config
    pre {
      delay = event:attrs{"delay"}
    }

    fired {
      ent:gossip_heartbeat_timer := delay if delay
    }

  }

  rule toggle_process {
    select when gossip process
    pre {
      process_data = event:attrs{"process_data"}
    }

    fired {
      ent:processor := ent:processor == "yep" => "nope" | "yep"
        if process_data
    } else {
      ent:processor := process_data
    } finally {
      schedule gossip event "heartbeat" at time:add(time:now(), {"seconds": ent:gossip_heartbeat_timer})
        if processing() ==  "yep" && schedule:list().none(function (x) 
          {
            x{"id"} == wrangler:myself(){"id"} && x{"event"}{"type"} == "heartbeat"
          })
    }

  }

  rule gossip_heartbeat_def {
    select when gossip heartbeat where processing() == "yep"
    pre {
      sub = get_peer()
      g = prepare_gossip(sub)
      pico = pid(g{"gossip"}{"message_id"})
      seq = sequence(g{"gossip"}{"message_id"})
    }

    if sub && g then
      event:send({
        "eci": sub{"Tx"},
        "domain": "gossip",
        "type": g{"type"},
        "attrs": g
      })

    fired {
      ent:seen_log{[sub{"Tx"}, pico]} := seq
        if 
          g{"type"} == "rumor" 
          && ((seen_log(){sub{"Tx"}}{pico}.isnull() && seq == 0)
              || seen_log(){sub{"Tx"}}{pico} + 1 == seq)
    } finally {
      schedule gossip event "heartbeat" at time:add(time:now(), {"seconds": ent:gossip_heartbeat_timer})
    }

  }

  rule gossip_rumor_handler {
    select when gossip rumor where processing() == "yep"
    pre {
      g = event:attrs{"gossip"}
      mid = g{"message_id"}
      pico = pid(mid)
      seq = sequence(mid)
    }
    if ent:latest{pico} then noop()
    
    fired {
      ent:latest{pico} := -1
    } finally {
      ent:rumor_log := ent:rumor_log.append(g)
        if rumor_log().none(function (v) 
        {
          v{"message_id"} == mid
        })
      
      ent:latest{pico} := proper_sequence(pico)
    }
  }

  rule gossip_seen_handler {
    select when gossip seen where processing() == "yep"
    pre {
      sender = event:attrs{"sender"}{"Rx"}
      g = event:attrs{"gossip"}
    }

    always {
      ent:seen_log{sender} := g
    }
  }

  rule register_gossiper {
    select when wrangler subscription_added
    pre {
      role = event:attrs{"bus"}["Tx_role"]
      tx = event:attrs{"bus"}["Tx"]
    }
    
    always {
      ent:seen_log{tx} := {} if role != "gossiper"
    }

  }
  
  rule new_temp_reading {
    select when wovyn heartbeat
    pre {
      temperature = event:attrs{"genericThing"}{"data"}{"temperature"}[0]{"temperatureF"}.klog("Temperature!")
      g = new_rumor(temperature)
    }
    always{
      ent:rumor_log := ent:rumor_log.append(g)
      ent:latest{wrangler:myself(){"id"}} := proper_sequence(wrangler:myself(){"id"})
      ent:my_sequence := ent:my_sequence + 1
    }
  }

}