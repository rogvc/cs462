ruleset temperature_store {
  meta {
    shares temperatures, threshold_violations, in_range_temperatures
    provides temperatures, threshold_violations, in_range_temperatures
  }

  global {
    __testing = {
      "queries": 
      [
        { "name": "__testing" },
        { "name": "temperatures" },
        { "name": "threshold_violations" },
        { "name": "in_range_temperatures" }
      ],
      "events": 
      [
        { 
          "domain": "sensor", 
          "name": "reset",
          "attrs": [] 
        }
      ]
    }

    temperatures = function () {
      ent:temperature_log
    }

    threshold_violations = function () {
      ent:violation_log
    }

    in_range_temperatures = function () {
      ent:temperature_log.filter(function (v, k) {
        is_violation(k)
      })
    }

    is_violation = function (timestamp) {
      ent:violation_log.keys().none(function (violation) {
        timestamp == violation
      })
    }
  }
  
  rule init {
    select when wrangler ruleset_added where event:attrs{"rids"} >< meta:rid

    always {
      ent:temperature_log := {}.klog("Initialized temperature_log")
      ent:violation_log := {}.klog("Initialized violation_log")
    }
  }

  rule collect_temperatures {
    select when wovyn new_temperature_reading

    pre {
      timestamp = event:attrs{"timestamp"}
      temperature = event:attrs{"generic_thing"}{"data"}{"temperature"}[0]{"temperatureF"}.klog(<<Collected temperature at #{timestamp}:>>)
    }

    always {
      ent:temperature_log{timestamp} := temperature
    }
  }

  rule collect_threshold_violations {
    select when wovyn threshold_violation
    
    pre {
      timestamp = event:attrs{"timestamp"}
      temperature = event:attrs{"temperature"}.klog(<<Collected violation at #{timestamp.decode()}: >>)
    }

    always {
      ent:violation_log{timestamp} := temperature
    }
  }

  rule clear_temperatures {
    select when sensor reset
    
    always {
      ent:temperature_log := {}
      ent:violation_log := {}
    }
  }
}