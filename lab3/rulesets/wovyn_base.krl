ruleset wovyn_base {
  meta {
    use module com.twilio.api alias twilio
      with
        sid = meta:rulesetConfig{"sid"}
        auth_token = meta:rulesetConfig{"auth_token"}
    
    configure using
      notification_sender_number = meta:rulesetConfig{"notification_sender_number"}
      notification_recipient_number = meta:rulesetConfig{"notification_recipient_number"}
      temperature_threshold = meta:rulesetConfig{"temperature_threshold"}
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
      if temperature > temperature_threshold
    }
  }

  rule threshold_notification {
    select when wovyn threshold_violation
    pre {
      temperature = event:attrs{"temperature"}.klog("Firing notification with temperature")
      timestamp = event:attrs{"timestamp"}
    }
    if temperature && timestamp then
      twilio:sendMessage(<<#{notification_recipient_number}>>, <<#{notification_sender_number}>>, <<Temperature #{temperature}F was too high. Reading happened at #{timestamp}>>) setting(response)
  }
}