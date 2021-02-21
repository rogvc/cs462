ruleset sensor_profile {
  meta {
    shares get_profile
  }

  global {
    get_profile = function () {
      {
        "name": ent:name,
        "location": ent:location,
        "temperature_threshold": ent:temperature_threshold,
        "notification_recipient": ent:notification_recipient 
      }
    }
  }

  rule init {
    select when wrangler ruleset_installed where event:attrs{"rids"} >< ctx:rid
    
    always {
      ent:name := ""
      ent:location := ""
      ent:temperature_threshold := null
      ent:notification_recipient := ""
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
}