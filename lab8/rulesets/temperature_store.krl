ruleset temperature_store {
  meta {
    shares temperatures, threshold_violations, in_range_temperatures, latest
    provides temperatures, threshold_violations, in_range_temperatures, latest
  }

  global {
    __testing = {
      "queries": 
      [
        { "name": "__testing" },
        { "name": "latest" },
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

    latest = function () {
      ent:latest_temperature
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
    select when wrangler ruleset_initialized where event:attrs{"rids"} >< meta:rid

    always {
      ent:temperature_log := {}.klog("Initialized temperature_log")
      ent:violation_log := {}.klog("Initialized violation_log")
      ent:latest_temperature := 0.0
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
      ent:latest_temperature := temperature
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

  rule report_temperatures_sg {
    select when sensor temperature_report_request
    pre {
      report_id = event:attrs{"report_id"}
      cid = event:attrs{"cid"}
    }

    always {
      raise sensor event "temperature_report_send"
        attributes {
          "report_id": report_id,
          "cid": cid,
          "temperatures": temperatures()
        }
    }
  }
}