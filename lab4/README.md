# Lab 4

## Screencast:

[View Screencast on YouTube](https://youtu.be/wTXrZkjJT8A)

## Rulesets URLs:

[temperature_store.krl](https://raw.githubusercontent.com/rogvc/cs462/master/lab4/rulesets/temperature_store.krl)

[wovyn_base.krl](https://raw.githubusercontent.com/rogvc/cs462/master/lab3/rulesets/wovyn_base.krl)

[com.twilio.api.krl](https://raw.githubusercontent.com/rogvc/cs462/master/lab2/rulesets/modules/com.twilio.api.krl)

### 1. Explain how the rule collect_temperatures and the temperatures function work as an event-query API.
`collect_temperatures` is the event that populates the `temperature_log` entity. This way, any time a new temperature is received by the **Temperature Sensor Pico**, the log grows. The `temperatures` query works as a simple getter for that log. Thus, by integrating an event, an entity, and a query, we form an event-query API.

### 2. Explain your strategy for finding temperatures that are in range.
I simply filter the `temperature_log` map by checking if any `timestamp` keys are also present in the `violation_log` map. Since both get set with identical `timestamp` keys, I can use that as a primary key of sorts. That way, when running the `none` operator on the `keys` array of the `violation_log` map, filter will only add the items that are in `temperature_log` and not in `violation_log`.

### 3. What happens if provides doesn't list the name of the temperatures function?
`temperature_store` would not be able to be used as a module on other rulesets. But it can still function on its own.

### 4. What happens if shares doesn't list it?
The functions in `temperature_store` would not be accessible in the **Testing** tab of the pico-engine, but they would still be accessible to any other rulesets that refer to it as a module. 
