# Lab 6

## Screencast:

Unfortunately, my computer could not record the screencast this time around. I'm running into issues with my graphics card on my desktop and my laptop doesn't have the hardware to handle everything going on at once.

## Diagram:

![pico-diagram](https://raw.githubusercontent.com/rogvc/cs462/master/lab6/resources/pico-diagram.png?raw=true)

## Rulesets URLs:

[manage_sensors.krl](https://raw.githubusercontent.com/rogvc/cs462/master/lab6/rulesets/sensor_profile.krl)

[sensor_profile.krl](https://raw.githubusercontent.com/rogvc/cs462/master/lab5/rulesets/sensor_profile.krl)

[temperature_store.krl](https://raw.githubusercontent.com/rogvc/cs462/master/lab4/rulesets/temperature_store.krl)

[wovyn_base.krl](https://raw.githubusercontent.com/rogvc/cs462/master/lab3/rulesets/wovyn_base.krl)

[com.twilio.api.krl](https://raw.githubusercontent.com/rogvc/cs462/master/lab2/rulesets/modules/com.twilio.api.krl)

### 1. How did your rule that creates the sensor pico install rules in the new child pico? 
I created a chain of events in which each event installs a different ruleset in the child Pico. This happens as each child is created.

### 2. How did you ensure that your sensor picos were created before sending them the event telling them their profile was updated? 
The ruleset installation chain of events selected on `wrangler:new_child_created` whereas the sensor profile configuration event was raised on `wrangler:child_initialized`.

### 3. How did you create a test harness for your pico system?
I manually tested each Pico and made sure all rulesets were installed and that the emitter was working properly on all of them. Also, I manually checked that values were changed when I trigerred a sensor profile update.

### 4. In this set up, the picos representing sensors don't need to talk to each other and the sensor management pico is the parent, so it has channels to each child. How could you provide channels between sensor picos if sensor-to-sensor interaction were necessary?
I'm assuming Wrangler has a way of programmatically creating channels that enable inter-pico communication. I would use those channels to achieve that.
