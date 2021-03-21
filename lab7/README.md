# Lab 7

## Screencast:

Unfortunately, my desktop is still struggling with its GPU and my laptop doesn't have the hardware to handle everything going on at once.

## Diagram:

![pico-diagram](https://raw.githubusercontent.com/rogvc/cs462/master/lab7/resources/pico-diagram.png?raw=true)

## Rulesets URLs:

[All rulesets can be found here](https://github.com/rogvc/cs462/tree/master/lab7/rulesets)

### 1. Why might an auto-approval rule for subscriptions be considered insecure? 
Because any subscription request, from anyone in the web will be automatically accepted, allowing malicious users to have access to our system.

### 2. Can you put a sensor pico in more than one sensor management pico (i.e. can it have subscriptions to more than one sensor management pico)? 
I think so? I don't see why not!

### 3. Imagine I have sensor types besides temperature sensors (e.g. pressure, humidity, air quality, etc.). How would you properly manage collections of sensors that include heterogeneous sensor types? 
Different sensor management rulesets and different domain names for events being triggered.

### 4. Describe how you'd use the techniques from this lesson to create collections of temperature sensors in particular rooms or areas of a building. For example, I would still have the sensor management pico, but might have collections for each floor in a building.
I'd add a sensor in each room and have it subscribe to the building manager Pico and perhaps a floor manager pico as well. Then, if there are any issues, they can communicate with each other and notify whoever is in charge, with an idea of a precise location of where the issue is.

### 5. Can a sensor pico belong to more than one collection? After the modifications of this lab, if a sensor belonged to more than one collection and had a threshold violation, what would happen? 
It can, and it would trigger violation notifications being sent out to multiple subscribers. In my code, however, I have only one manager pico. I could easily change that to be a list of managers and trigger the notification in each of them if needed.

### 6. When you moved threshold violation notifications from the sensor to the management ruleset, did you add the rules to an existing ruleset or create a new one? Why? 
I simply changed what the `wovyn_base` ruleset called once it found a threshold violation. I did it because it seemed like the simplest way to isolate changes to the system's functionality.

### 7. When you moved threshold violation notifications from the sensor to the management ruleset, did you add only one rule or more than one rule to achieve this end? Which rules did you add and why (i.e. justify the architectural decisions did you made)?
Only one rule was added, that helps me isolate the changes and makes it simpler to add further modifications to the system later.