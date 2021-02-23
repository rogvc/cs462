# Lab 5

## Screencast:

[View Screencast on YouTube](https://youtu.be/H8wDEXOBM50)

## Rulesets URLs:

[sensor_profile.krl](https://raw.githubusercontent.com/rogvc/cs462/master/lab5/rulesets/sensor_profile.krl)

[temperature_store.krl](https://raw.githubusercontent.com/rogvc/cs462/master/lab4/rulesets/temperature_store.krl)

[wovyn_base.krl](https://raw.githubusercontent.com/rogvc/cs462/master/lab3/rulesets/wovyn_base.krl)

[com.twilio.api.krl](https://raw.githubusercontent.com/rogvc/cs462/master/lab2/rulesets/modules/com.twilio.api.krl)

### 1. What design decisions did you make in your rulesets that made this assignment easier or harder? Why? 
Making my rulesets use user-provided data made the assignment very much doable. It was quick and painless to make data available and editable. Also, creating a `permissive` channel on my Pico allowed me to test all my features without any permissions issues.

### 2. Explain how the `sensor_profile` ruleset isolates state and processes regarding the sensor profile from other rulesets. 
The sensor profile holds its own data that doesn't really affect any other Rulesets, save for the `temperature_store` ruleset, that selects a rule when `wovyn:config` is raised by `sensor_profile`, with a new temperature threshold value.

### 3. How do other rulesets use the `sensor_profile` to get data?
They can simply call the shared/provided function or raise the `sensor:profile_updated` event to communicate with it. 

### 4. Could they use it to store new values? How?
They could, and they would have to communicate through a chain of events. Refer to the answer above to see what event they should raise.
