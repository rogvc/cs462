# Lab 9

## Screencast:

[View Screencast on YouTube](https://youtu.be/P1GRQ1_2hYM)

## Rulesets URLs:

[All rulesets can be found here](https://github.com/rogvc/cs462/tree/master/lab9/rulesets)

### 1. This lab uses a vector clock algorithm to create unique message IDs based on a sequence number. Could we replace the sequence number with a timestamp? What are the advantages and disadvantages of such an approach?
We could do it, it would be just a matter of switching what I append to the message_id. The advantage would be having an even uniquer (if that's a word) id for each rumor, but we would lose on readablity, I believe.

### 2. Are the temperature messages in order? Why or why not? If not, what could you do to fix this?  
They are not in order, but I could just sort the array by the message_id number and then we should get a perfectly sorted rumor list.

### 3. How did you avoid looping (sending messages back to someone who already has it)? Why was the unique ID helpful?
Unique IDs helped keeping track of what did not need to be sent. Once a Pico receives a rumor, it knows for a fact it has that rumor, then it can just skip it and/or not ask for it from other Picos.

### 4. The propagation algorithm sleeps for n seconds between each iteration. What are the trade-offs between a low and high value for n.  
Low values can end up in performance issues (depending on which machine is hosting the pico engine, and how many picos we have), and high values can cause a significant delay in synchronizing the data.

### 5. Did new messages eventually end on all the nodes that were connected? Were the messages displayed in the same order on each node? Why or why not? 
Yes, they did. They were not in order because they got the rumors on a case-by-case basis. If Pico 1 got the rumor from Pico 3 before Pico 4 did, then it wouldn't try to synchronize with Pico 4 because it probably doesn't even know/care that Pico 4 exists.

### 6. Why does temporarily disconnecting a node from the network not result in permanent gaps in the messages seen at that node?
Because there's no central point of failure. Picos are independent.

### 7. Describe, in a paragraph or two, how you could use the basic scheme implemented here to add failure detection to the system using a reachability table.
I think the way I have implemented it is already pretty failsafe. Everytime I shut down a Pico using the `process` rule, it's akin to having it fail, because it stops syncing with the other Picos. Once it turns on, it tries its best to get the `latest` status from each Pico it's connected to, and eventually requests every rumor it hasn't received up to the latest reported rumor from its peers. That way, once there is failure, the Pico can recover as soon as it's up and running again.