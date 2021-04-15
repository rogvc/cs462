ruleset gossip_manager {
  meta {
    use module io.picolabs.subscription alias subs
    use module io.picolabs.wrangler alias wrangler

    shares show_threshold, show_in_violation, show_nodes_violation, show_rumor_log, show_seen_log, show_latest_data, show_is_active
  }
  global {
    show_threshold = function () {
      ent:temperature_threshold
    }

    show_in_violation = function () {
      ent:in_violation
    }

    show_nodes_violation = function () {
      ent:violation_counter
    }

    show_rumor_log = function () {
      ent:rumor_log
    }
    
    show_seen_log = function () {
      ent:seen_log
    }
    
    show_latest_data = function () {
      ent:latest_data
    }
    
    show_is_active = function () {
      ent:is_active
    }
    
    state_of = function (seen_data) {
      ent:rumor_log.filter(function (v)
      {
        id = pid(v{"message_id"})
        seen_data{id}.isnull() || (seen_data{id} < sequence_of(v{"message_id"}))
      }).sort(function (x, y) 
      {
        sequence_of(x{"message_id"}) <=> sequence_of(y{"message_id"})
      })
    }
    
    find_peer = function () {
      all_subs = subs:established("Rx_role", "gossiper")

      in_need = ent:seen_log.filter(function (v, k)
      {
        state_of(v).length() > 0
      })
      
      chosen_one = in_need.keys()[random:integer(in_need.length() - 1)]
      
      in_need.length() < 1 => 
        all_subs[random:integer(all_subs.length() - 1)] 
        | all_subs.filter(function (s) 
          {
            s{"Tx"} == chosen_one
          }).head()
    }
    
    proper_sequence_of = function (pico) {
      rumors = ent:rumor_log.filter(function (v)
      {
        id = pid(v{"message_id"})
        id == pico
      }).map(function (v)
      {
        sequence_of(v{"message_id"})
      })

      sorted = rumors.sort(function (x, y) 
      {
        x <=> y
      })

      sorted.reduce(function(x, y) 
      { 
        (y == x + 1) => y | x 
      }, -1)
    }
        
    create_gossip = function (subscriber) {
      r = random:integer(0, 10)
      message = r < 3 
        => create_rumor(subscriber) 
        | r > 6 => create_seen(subscriber) | create_violation_rumor(subscriber)
      m = message{"message"}.isnull() => create_seen(subscriber) | message
      m
    }
    
    create_violation_rumor = function (subscriber) {
      return {
        "message": ent:violation_val,
        "type": "violation",
        "sender": subscriber
      }
    }

    create_rumor = function (subscriber) {
      missing = state_of(ent:seen_log{subscriber{"Tx"}})
      return { 
        "message": missing.isnull() => null | missing[0],
        "type": "rumor" 
      }
    }
    
    create_seen = function (subscriber) {
      return {
        "message": ent:latest_data, 
        "sender": subscriber,
        "type": "seen"
      } 
    }
    
    sequence_of = function (message_id) {
     split_message_id = message_id.split(re#:#)
     split_message_id[split_message_id.length() - 1].as("Number")
    }
    
    pid = function (message_id) {
     message_id.split(re#:#)[0]
    }
    
    create_message_id = function () {
      return wrangler:myself(){"id"} + ":" + ent:my_sequence
    }
    
    create_rumor_message = function (temperature) {
      {
        "message_id": create_message_id(),
        "sensor_id": wrangler:myself(){"id"},
        "temperature": temperature,
        "timestamp": time:now()
      }
    }
   
  }
  
  rule init {
    select when wrangler ruleset_installed where event:attrs{"rids"} >< ctx:rid
    always {
        ent:gossip_heartbeat_rate := random:integer(5, 15);
        ent:my_sequence := 0;
        ent:rumor_log := [];
        ent:latest_data := {}
        ent:seen_log := {}
        ent:is_active := "yep"
        ent:violation_counter := 0
        ent:temperature_threshold := random:integer(75, 85)
        ent:in_violation := false
        ent:violation_val := 0
        schedule gossip event "heartbeat" at time:add(time:now(), {"seconds": 5}).klog("Scheduling Gossip Heartbeat...")
    }
  }

  rule on_heartbeat_update {
    select when gossip update_heartbeat
    pre{
      new_rate = event:attrs{"heartbeat_rate"}
    }

    if not new_rate.isnull() then noop()
    
    fired {
      ent:gossip_heartbeat_rate := new_rate
    }
  }
  
  rule on_active_toggle {
    select when gossip process
    pre{
      process = event:attrs{"status"}
    }
    
    if process.isnull() || (process != "yep" && process != "nope") then noop()
    
    fired {
      ent:is_active := ent:is_active == "yep" => "nope" | "yep"
    } else {
      ent:is_active := process
    } finally { 
      schedule gossip event "heartbeat" at time:add(time:now(), {"seconds": ent:gossip_heartbeat_rate}).klog("Scheduling Gossip Heartbeat...")
        if ent:is_active == "yep" && schedule:list().none(function (action) 
        { 
          action{"id"} == wrangler:myself(){"id"} 
          && action{"event"}{"domain"} == "gossip" 
          && action{"event"}{"type"} == "heartbeat"
        })
    }
  }
  
  rule on_gossip_heartbeat {
    select when gossip heartbeat where ent:is_active == "yep"
    pre {
      subscriber = find_peer()
      m = create_gossip(subscriber)
      m_pico = pid(m{"message"}{"message_id"})
      m_sequence = sequence_of(m{"message"}{"message_id"})
    }
    
    if subscriber.isnull() == false && m.isnull() == false then 
      event:send
      ({
          "eci": subscriber{"Tx"},
          "domain": "gossip", 
          "type": m{"type"},
          "attrs": m
      })

    fired{ 
      ent:seen_log{[subscriber{"Tx"}, m_pico]} :=  m_sequence
        if m{"type"} == "rumor" 
           && ((ent:seen_log{subscriber{"Tx"}}{m_pico}.isnull() && m_sequence == 0) 
                || ent:seen_log{subscriber{"Tx"}}{m_pico} + 1 == m_sequence)
    } finally{
      schedule gossip event "heartbeat" at time:add(time:now(), {"seconds": ent:gossip_heartbeat_rate}).klog("Scheduling Gossip Heartbeat...")
    }
  }

  rule on_gossip_rumor {
    select when gossip rumor where ent:is_active == "yep"
    pre {
      message = event:attrs{"message"}
      message_id = message{"message_id"}
      pico = pid(message_id)
      sequence = sequence_of(message_id)
    }

    if ent:latest_data{pico}.isnull() then noop()

    fired {
      ent:latest_data{pico} := -1
    } finally {
      ent:rumor_log := ent:rumor_log.append(message)
        if ent:rumor_log.none(function (x)
        {
          x{"message_id"} == message_id 
        })
      
      ent:latest_data{pico} := proper_sequence_of(pico)
    }
  }
  
  rule on_gossip_seen {
    select when gossip seen where ent:is_active == "yep"
    pre {
      sender = event:attrs{"sender"}{"Rx"}
      message = event:attrs{"message"}
    }
    always {
      ent:seen_log{sender} := message
    }
  }

  rule on_gossip_violation {
    select when gossip violation where ent:is_active == "yep"
    pre {
      sender = event:attrs{"sender"}{"Rx"}
      message = event:attrs{"message"}
    }
    always {
      ent:violation_counter := ent:violation_counter + message
    }
  }
  
  rule on_gossiper_subscription_added {
    select when wrangler subscription_added
    pre {
      tx_role = event:attrs{"bus"}["Tx_role"]
      tx = event:attrs{"bus"}["Tx"]
    }
    
    if tx_role == "gossiper" then noop()
    
    fired{
      ent:seen_log{tx} := {}
    }
  }
  
  rule on_subscribe_to_gossiper {
    select when gossip subscribe_to_neighbor
    pre {
      incoming_tx = event:attrs{"Tx"}
      incoming_name = event:attrs{"name"}
      host = event:attrs{"Tx_host"}
    }
    always {
      raise wrangler event "subscription" attributes 
        {
          "wellKnown_Tx" : incoming_tx,
          "name" : incoming_name,
          "Rx_role": "gossiper",
          "Tx_role": "gossiper",
          "channel_type": "subscription",
          "Tx_host": host
        };
    }
  }
  
  rule on_wovyn_heartbeat {
    select when wovyn heartbeat
    pre {
      temperature = event:attrs{"genericThing"}{"data"}{"temperature"}[0]{"temperatureF"}
      message = create_rumor_message(temperature)
    }
    always{
      ent:rumor_log := ent:rumor_log.append(message)
      ent:latest_data{wrangler:myself(){"id"}} := proper_sequence_of(wrangler:myself(){"id"})
      ent:my_sequence := ent:my_sequence + 1
      raise gossip event "violation_check" attributes
      {
        "temperature": temperature
      }
    }
  }

  rule on_new_threshold {
    select when gossip new_threshold
    pre {
      threshold = event:attrs{"threshold"}
    }

    always {
      ent:temperature_threshold := threshold
    }
  }

  rule on_violation_check {
    select when gossip violation_check
    pre {
      temperature = event:attrs{"temperature"}
      is_violation = temperature >= ent:temperature_threshold
    }

    always {
      raise gossip event "new_violation" if (is_violation && not ent:in_violation).klog("Should schedule new violation")
      raise gossip event "cancel_violation" if (not is_violation && ent:in_violation).klog("Should schedule cancel violation")
      raise gossip event "same_violation" if (is_violation == ent:in_violation).klog("Should schedule same violation")
    }    
  }

  rule on_new_violation {
    select when gossip new_violation
    always {
      ent:in_violation := true
      ent:violation_val := 1
      ent:violation_counter := ent:violation_counter + 1
    }
  }

  rule on_cancel_violation {
    select when gossip cancel_violation
    always {
      ent:in_violation := false
      ent:violation_val := -1
      ent:violation_counter := ent:violation_counter - 1
    }
  }

  rule on_same_violation {
    select when gossip same_violation
    always {
      ent:violation_val := 0
    }
  }

}