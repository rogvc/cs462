ruleset sensor_profile {
  meta {
    use module io.picolabs.wrangler alias wrangler
    use module io.picolabs.subscription alias subs   
    use module temperature_store alias temps

    shares get_profile
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

    // event:send(
    //   {
    //     "eci": parent_eci,
    //     "domain": "sensor",
    //     "type": "identify_child",
    //     "attrs": 
    //       {
    //         "name": name,
    //         "eci": eci,
    //         "wellKnown_eci": wellKnown_eci
    //       }
    //   }
    // )

    always {
      ent:id := random:uuid()
      ent:name := "Gossiper " + random:word() 
      ent:location := "Bedroom"
      ent:temperature_threshold := 80
      ent:notification_recipient := ""
      ent:manager_eci := ""
      ent:rumor_log := {}
      ent:seen_log := {}
      ent:message_count := 0
      ent:message_id := random:uuid().klog("message_id created")
      // raise sensor event "create_subscription_channel"
      //   attributes event:attrs
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

  rule rumor_origin {
    select when gossip create_rumor
    pre {
      message_id = ent:message_id
      message_count = ent:message_count
      sensor_id = ent:id.klog("sensor_id retrieved")
      temperature = temps:latest().klog("temperature reading received")
      timestamp = time:now().klog("timestamp established")
    }

    always {
      raise gossip event "start_rumor" attributes
        {
          "message_id": message_id,
          "message_count": message_count,
          "sensor_id": sensor_id,
          "temperature": temperature,
          "timestamp": timestamp
        }
    }
  }

  rule rumor_begin_spreading {
    select when gossip start_rumor
    foreach subs:established() setting (sub)

    event:send({
      "eci": sub{"Tx"},
      "eid": "starting rumor",
      "domain": "gossip",
      "type": "receive_rumor",
      "attrs": event:attrs
    })

    always {
      ent:rumor_log := ent:rumor_log{sensor_id}.union({
        "message_id": message_id,
        "message_count": message_count,
        "sensor_id": sensor_id,
        "temperature": temperature,
        "timestamp": timestamp
      })
      ent:message_count := message_count + 1
    }

  }

  rule rumor_receive {
    select when gossip receive_rumor
    pre {
      message_id = event:attrs{"message_id"}
      message_count = event:attrs{"message_count"}
      sensor_id = event:attrs{"sensor_id"}
      temperature = event:attrs{"temperature"}
      timestamp = event:attrs{"timestamp"}
    }

    always {
      ent:rumor_log := ent:rumor_log{sensor_id}.union({
        "message_id": message_id,
        "message_count": message_count,
        "sensor_id": sensor_id,
        "temperature": temperature,
        "timestamp": timestamp
      })
      
      ent:seen_log{sensor_id} := message_count
    }
  }
}