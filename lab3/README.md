# Lab 3

## Screencast:

[View Screencast on YouTube](https://youtu.be/ituyjY7xdCs)

## Rulesets URLs:

[wovyn_base.krl](https://raw.githubusercontent.com/rogvc/cs462/master/lab3/rulesets/wovyn_base.krl)

[com.twilio.api.krl](https://raw.githubusercontent.com/rogvc/cs462/master/lab2/rulesets/modules/com.twilio.api.krl)

### 1. What parsing method did you choose?  
I am simply retrieving data from the `event:attrs` map, and I'm trusting krl's JSON parser to retrieve the correct type of variable from the event body.


### 2. Did you accomplish step 5 with an event expression or a rule conditional statement? What are the advantages and disadvantages of the method you used compared with the other?
I believe I used a conditional statement. I think the advantage is that the code is cleaner that way, and if I need to change the condition under which an expression is computed, I simply need to change the the trailing `if` check.  

### 3. What was the output of testing your ruleset before the `find_high_temps` rule was added? How many directives were returned? How many rules do you think ran?  
It was simply the logs from my `process_heartbeat` rule. The only directives being returned were those being fired by the aforementioned rule, since there were no events tiggering on `wovyn:new_temperature_reading` at the time.

### 4. What was the output of the test after the `find_high_temps` rule was added? How many directives were returned? How many rules do you think ran?  
I got the logs from both rules, since both events were being triggered and their subsequent rules were being selected, which means that only these two rules ran (at least as far as my code is concerned). I believe there was only one main directive being returned, with subsequent actions being display under the directive's contents in the **Logging** tab.

### 5. How do you account for the difference? Diagram the event flow within the pico (i.e. show the event flow from when the pico receives the first event to the directives being created) using a [swimlane diagram](https://swimlanes.io/).  
You can see the diagram [here](https://swimlanes.io/#rZJBasQwDEX3PoUukB4gi5yh0IFZxqqtxAJHCraa0Ns3U8ikXTSlTJcS0vt6IGPL1MKVctCJwBTqylNGofrE6py76vIu8EJStUDTwYWmmQraW6G9+8xB21sRKyTCYq+EBhENQQXqTIEHpgghoQhl535gQNN0JwF+vZ3S3hM8wAnq9NJMwSqgRBi4UAU/Fw1Ua3/AneNhy6SFxFo0K9VDUDFk2eZHEiocLoll9A8KCa29HTN9IYy/YP8mN7DEPvGYPmPqrvYl00P3re4tbZtJc3xU7g7qF9aMxir/J3bARW37sbDzPwA=).

### 6. Would you say that your `find_high_temps` rule is an event intermediary? If so, what kind? Justify your answer.
I would say it is, because it acts as some sort of gatekeeper for what follows it. If `find_high_temps` determines that the temperature is not high enough, the chain of events stops right there; otherwise, it will continue as determined by the rules in this ruleset.

### 7. How do your logs show that the `find_high_temps` rule works? Pick out specific lines and explain them.
I have at least one log for each even triggered, so if I check the **Logging** tab and see three user-defined logs, it means that my events are getting triggered and their respective rules are getting selected correctly.
