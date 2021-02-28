ruleset manage_sensors {
  meta {
    use module io.picolabs.wrangler alias wrangler
    
    shares get_sensors, already_contains, get_all_temperatures
  }

  global {
    __testing = {
      "queries": 
      [
        { "name": "__testing" },
        { "name": "get_sensors" },
        { 
          "name": "already_contains", 
          "args": [
            "name"
          ]
        },
        { "name": "get_all_temperatures" },
      ],
      "events":
      [
        { 
          "domain": "sensor", 
          "name": "clear_sensors",
          "attrs": [] 
        },
        { 
          "domain": "sensor", 
          "name": "new_sensor",
          "attrs": [] 
        },
        { 
          "domain": "sensor", 
          "name": "unneeded_sensor",
          "attrs": [
            "name"
          ] 
        }
      ]
    }

    default_temp_threshold = 100

    create_pico_name = function () {
      <<Sensor #{wrangler:children().length() + 1}>>
    }

    already_contains = function (name) {
      ent:sensors.keys().any(function(v) {
        v == name
      })
    }

    get_sensors = function () {
      ent:sensors
    }

    get_all_temperatures = function () {
      get_sensors().values().map(function (eci) {
        wrangler:picoQuery(eci, "temperature_store", "temperatures")
      })
    }
  }

  rule init {
    select when wrangler ruleset_installed where event:attrs{"rids"} >< ctx:rid
    
    always {
      ent:sensors := {}
    }
  }

  rule trigger_new_sensor_creation {
    select when sensor new_sensor

    always {
      raise wrangler event "new_child_request"
        attributes 
          {
            "name": create_pico_name()
          }
      if not already_contains(create_pico_name()).klog("already in sensors?")
    }
  }

  rule on_child_created {
    select when wrangler new_child_created

    pre {
      eci = event:attrs{"eci"}
      name = event:attrs{"name"}
    }

    fired {
      raise sensor event "temperature_store_child"
        attributes event:attrs
    }
  }

  rule on_child_initialized {
    select when wrangler child_initialized
    
    pre {
      eci = event:attrs{"eci"}
      name = event:attrs{"name"}
    }

    event:send({
      "eci": eci,
      "eid": "initialize-pico",
      "domain": "sensor", "type": "profile_updated",
      "attrs": {
        "name": name,
        "location": "default",
        "temperature_threshold": default_temp_threshold,
        "notification_recipient": "+18016716928"
      }
    })
  }

  rule install_temperature_store_child {
    select when sensor temperature_store_child
    
    pre {
      eci = event:attrs{"eci"}
      name = event:attrs{"name"}
    }
    
    event:send(
      {
        "eci": eci,
        "eid": "install-ruleset",
        "domain": "wrangler", "type": "install_ruleset_request",
        "attrs": {
          "absoluteURL": meta:rulesetURI,
          "rid": "temperature_store",
          "config": {}
        }
      }
    )

    always {
      raise sensor event "twilio_child"
        attributes event:attrs
    }
  }

  rule install_twilio_in_child {
    select when sensor twilio_child

    pre {
      eci = event:attrs{"eci"}
      name = event:attrs{"name"}
    }

    event:send(
      {
        "eci": eci,
        "eid": "install-ruleset",
        "domain": "wrangler", "type": "install_ruleset_request",
        "attrs": {
          "absoluteURL": meta:rulesetURI,
          "rid": "com.twilio.api",
          "config": {"sid":"ACadaff6b9168f457f852363e5f6f09e0a","auth_token":"fe537ab9b06a5314eb10a9ff4a083ead","temperature_threshold":80.3,"notification_sender_number":"+18018892129","notification_recipient_number":"+18016716928"}
        }
      }
    )

    always {
      raise sensor event "wovyn_base_child"
        attributes event:attrs
    }
  }

  rule install_wovyn_base_in_child {
    select when sensor wovyn_base_child

    pre {
      eci = event:attrs{"eci"}
      name = event:attrs{"name"}
    }

    event:send(
      {
        "eci": eci,
        "eid": "install-ruleset",
        "domain": "wrangler", "type": "install_ruleset_request",
        "attrs": {
          "absoluteURL": meta:rulesetURI,
          "rid": "wovyn_base",
          "config": {"sid":"ACadaff6b9168f457f852363e5f6f09e0a","auth_token":"fe537ab9b06a5314eb10a9ff4a083ead","temperature_threshold":80.3,"notification_sender_number":"+18018892129","notification_recipient_number":"+18016716928"}
        }
      }
    )

    always {
      raise sensor event "sensor_profile_child"
        attributes event:attrs
    }
  }

  rule install_sensor_profile_in_child {
    select when sensor sensor_profile_child

    pre {
      eci = event:attrs{"eci"}
      name = event:attrs{"name"}
    }

    event:send(
      {
        "eci": eci,
        "eid": "install-ruleset",
        "domain": "wrangler", "type": "install_ruleset_request",
        "attrs": {
          "absoluteURL": meta:rulesetURI,
          "rid": "sensor_profile",
          "config": {}
        }
      }
    )

    always {
      raise sensor event "emitter_child"
        attributes event:attrs
    }
  }

  rule install_emiter_in_child {
    select when sensor emitter_child

    pre {
      eci = event:attrs{"eci"}
      name = event:attrs{"name"}
    }

    event:send(
      {
        "eci": eci,
        "eid": "install-ruleset",
        "domain": "wrangler", "type": "install_ruleset_request",
        "attrs": {
          "absoluteURL": meta:rulesetURI,
          "rid": "io.picolabs.wovyn.emitter",
          "config": {}
        }
      }
    )

    always {
      raise sensor event "store_new_sensor"
        attributes event:attrs
    }
  }

  rule store_new_sensor {
    select when sensor store_new_sensor

    pre {
      name = event:attrs{"name"}
      eci = event:attrs{"eci"}
    }

    always {
      ent:sensors{name} := eci
    }
  }

  rule clear_sensors {
    select when sensor clear_sensors

    always {
      ent:sensors := {}
    }
  }

  rule remove_sensor {
    select when sensor unneeded_sensor

    pre {
      name = event:attrs{"name"}
      eci = get_sensors(){name}
    }

    always {
      clear ent:sensors{name}
      raise wrangler event "child_deletion_request"
        attributes {"eci": eci}
    }
  }

}