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
      g = random:integer(10) < 6 => prepare_rumor(sub) | prepare_seen(sub)
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
        "message_id": wrangler:picoId + ":" + ent:my_sequence,
        "sensor_id": wrangler:picoId,
        "temperature": temperature,
        "timestamp": time:now()
      }
    }


  }

  rule config {
    select when sensor standalone_config
    pre {
      name = event:attrs{"name"}
      location = event:attrs{"location"}
      temp = event:attrs{"temperature_threshold"}
    }

    always {
      ent:id := random:uuid()
      ent:name := name
      ent:location := location
      ent:temperature_threshold := temp
      ent:notification_recipient := ""
    }
  }

  rule init {
    select when wrangler ruleset_installed where event:attrs{"rids"} >< ctx:rid

    pre {
      name = event:attrs{"name"}
      eci = wrangler:myself(){"eci"}
      parent_eci = wrangler:parent_eci()
      wellKnown_eci = subs:wellKnown_Rx(){"id"}
    }

    always {
      ent:id := random:uuid()
      ent:name := "Gossiper " + random:word() 
      ent:location := "Bedroom"
      ent:temperature_threshold := 80
      ent:notification_recipient := ""
      ent:manager_eci := ""
      ent:rumor_log := []
      ent:my_sequence := 0
      ent:latest := {}
      ent:seen_log := {}
      // ent:message_count := 0
      // ent:message_id := random:uuid().klog("message_id created")
      ent:gossip_heartbeat_timer := 15
      ent:processor := "yep"

      schedule gossip event "heartbeat" at time:add(time:now(), {"minutes": 3})
    }
  }

  rule prepare_for_subscription {
    select when sensor create_subscription_channel

    if ent:sensor_eci.isnull() then
      wrangler:createChannel(tags, eventPolicy, queryPolicy) setting(channel)
    
    fired {
      ent:name := event:attrs{"name"}.klog("Entity Name: ")
      ent:wellKnown_Rx := wrangler:parent_eci().klog("Entity WellKnown_Rx: ")
      ent:sensor_eci := channel{"id"}.klog("Entity sensor_eci: ")

      raise sensor event "new_subscription_request"
    }
  }

  rule make_subscription {
    select when sensor new_subscription_request
    
    event:send(
      {
        "eci": ent:wellKnown_Rx,
        "domain": "wrangler",
        "name": "subscription",
        "attrs": {
          "wellKnown_Tx": subs:wellKnown_Rx(){"id"},
          "Rx_role": "sensory", "Tx_role": "sensor",
          "name": ent:name+"-sensory", "channel_type":"subscription"
        }
      }
    )
  }

  rule on_subscription_established {
    select when wrangler subscription_added

    pre {
      role = event:attrs{"Rx_role"}.klog("Role: ")
    }
    
    if (role == "sensor") then
      event:send(
        {
          "eci": event:attrs{"Tx"},
          "eid": "sign_me_up",
          "domain": "sensor",
          "type": "identify_subscription",
          "attrs": {
            "name": ent:name,
            "eci": wrangler:myself(){"eci"}
          }
        }
      )

    always {
      raise self event "register_manager"
      attributes { "eci": event:attrs{"Tx"} }
      if (role == "sensor")
    }
  }

  rule register_sensor_manager {
    select when self register_manager
    always {
      ent:manager_eci := event:attrs{"eci"}
    }
  }

  rule auto_accept_subscriptions {
    select when wrangler inbound_pending_subscription_added
    fired {
      raise wrangler event "pending_subscription_approval"
        attributes event:attrs
    }
  }

  rule update_profile {
    select when sensor profile_updated

    pre {
      name = event:attrs{"name"}

      location = event:attrs{"location"}
      temperature_threshold = event:attrs{"temperature_threshold"}.decode()
      notification_recipient = event:attrs{"notification_recipient"}

    }

    always {
      ent:name := name
      ent:location := location
      ent:temperature_threshold := temperature_threshold
      ent:notification_recipient := notification_recipient

      raise wovyn event "config" attributes
        {
          "notification_recipient_number": ent:notification_recipient,
          "temperature_threshold": ent:temperature_threshold
        }
    }

  }

  rule on_temperature_violation {
    select when sensor notify_high_temperature
    event:send(
        {
          "eci": ent:manager_eci,
          "eid": "too_hot",
          "domain": "sensor",
          "type": "temperature_violation",
          "attrs": event:attrs
        }
      )
  }

  rule report_temperatures_sg {
    select when sensor temperature_report_send
    pre {
      report_id = event:attrs{"report_id"}
      cid = event:attrs{"cid"}
      temperatures = event:attrs{"temperatures"}
    }
    
    event:send(
      {
        "eci": ent:manager_eci,
        "eid": "temperature_report",
        "domain": "sensor",
        "type": "temperature_report_response",
        "attrs": {
          "name": ent:name,
          "report_id": report_id,
          "cid": cid,
          "temperatures": temperatures
        }
      }
    )
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
            x{"id"} == wrangler:picoId && x{"event"}{"type"} == "heartbeat"
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
      ent:seen_log{tx} := {} if role == "gossiper"
    }

  }
  
  rule new_local_temp_reading {
    select when wovyn heartbeat
    pre {
      attrs = event:attrs.klog("attributes.")
      temperature = event:attrs{"genericThing"}{"data"}{"temperature"}{"temperatureF"}
      g = new_rumor(temperature)
    }
    always{
      ent:rumor_log := ent:rumor_log.append(g)
      ent:latest{wrangler:picoId} := proper_sequence(wrangler:picoId)
      ent:my_sequence := ent:my_sequence + 1
    }
  }

}