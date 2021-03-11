ruleset wovyn_base {
  meta {
    use module com.twilio.api alias twilio
      with
        sid = meta:rulesetConfig{"sid"}
        auth_token = meta:rulesetConfig{"auth_token"}
    
    configure using
      notification_sender_number = meta:rulesetConfig{"notification_sender_number"}
    shares get_config  
  }

  global {
    get_config = function () {
      {
        "sender_number": notification_sender_number,
        "recipient_number": ent:notification_recipient,
        "temperature_threshold": ent:temperature_threshold,
      }
    }
  }

  rule init {
    select when wrangler ruleset_installed where event:attrs{"rids"} >< ctx:rid
    always {
      ent:notification_recipient := meta:rulesetConfig{"notification_recipient_number"}.klog("Sending messages to this number")
      ent:temperature_threshold := meta:rulesetConfig{"temperature_threshold"}.klog("Temperature threshold")
    }
  }

  rule set_sensor_configuration {
    select when wovyn config
    pre {
      notification_recipient = event:attrs{"notification_recipient_number"}.klog("New recipient number")
      temperature_threshold = event:attrs{"temperature_threshold"}.klog("New temperature threshold")
    }
    always {
      ent:notification_recipient := notification_recipient
      ent:temperature_threshold := temperature_threshold
      
      raise twilio event "configure"
        attributes {
          "sid": meta:rulesetConfig{"sid"},
          "auth_token": meta:rulesetConfig{"auth_token"}
        }
    }
  }

  rule process_heartbeat {
    select when wovyn heartbeat
    pre {
      generic_thing = event:attrs{"genericThing"}
      timestamp = time:now().klog("Got Heartbeat at")
    }
    
    always {
      raise wovyn event "new_temperature_reading"
        attributes {
          "generic_thing": generic_thing,
          "timestamp": timestamp
        }
      if generic_thing
    }    
  }

  rule find_high_temps {
    select when wovyn new_temperature_reading
    pre {
      temperature = event:attrs{"generic_thing"}{"data"}{"temperature"}[0]{"temperatureF"}.klog("Got temperature: ")
      timestamp = event:attrs{"timestamp"}
    }

    always {
      raise wovyn event "threshold_violation"
        attributes {
          "temperature": temperature,
          "timestamp": timestamp
        }
      if temperature > ent:temperature_threshold
    }
  }

  rule threshold_notification {
    select when wovyn threshold_violation
    pre {
      temperature = event:attrs{"temperature"}.klog("Firing notification with temperature")
      timestamp = event:attrs{"timestamp"}.klog("Timing")
    }
    always {
      raise sensor event "notify_high_temperature"
        attributes {"message":<<Temperature #{temperature}F was too high. Reading happened at #{timestamp}>>}
        if temperature && timestamp
    }
    
  }
}