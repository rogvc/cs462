# Lab 8

## Screencast:

[View Screencast on YouTube](https://youtu.be/jmMTwGg4nig)

## Rulesets URLs:

[All rulesets can be found here](https://github.com/rogvc/cs462/tree/master/lab8/rulesets)

### 1. Can a sensor be in more than one collection based on the code you wrote? Why or why not? What are the implications of a sensor being in more than one collection? 
Yes, it can be in many collections as it needs, because the sensor Pico can receive as many requests as it needs. This system is a simple event call, and Picos are made to react to those. The implication would be getting the same data in different places. 

### 2. How could you ensure that only certain picos can raise an event that causes a temperature report to be generated? 
I can check the subscription role of a subscription before I perform any computations or raise any events.

### 3. How do the debug logs show that your scatter-gather system worked?
I can see that the rule was selected on the correct event in each Pico. 

### 4. How can you know a report is done and all the sensors that are going to respond have reported? 
Since I have both the total number of events raised and the number of responses being collected, I can just check if the number or responses equals the number of requests.

### 5. Given your answer above, how would you recover if the number of responding sensors is less than the total number of sensors? 
I can also track requests through their unique ids. That way, I could check which request is missing a response and troubleshoot the correct Pico from there.