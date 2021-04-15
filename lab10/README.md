# Lab 10

## Screencast:

[View Screencast on YouTube](https://youtu.be/P1GRQ1_2hYM)

## Rulesets URLs:

[All rulesets can be found here](https://github.com/rogvc/cs462/tree/master/lab10/rulesets)

### 1. Did you use a single message identifier for all message types in your system, or different one for each type of message? Why?  
I used one message ID per sender. That allows me to know where all messages are coming from.

### 2. Did you have to change how your seen messages worked? Why or why not? 
Not particularly, because my temperature messages were independent from all other messages. Before, I had a 50/50 chance of sending a rumor or seen on a heartbeat, but now I have a 33% chance of sending a rumor, seen, or temperature on each gossip heartbeat.

### 3. How did the state-oriented CRDT we used for Lab 9 differ from the operation-oriented CRDT we used in this lab? 
Before, even though picos knew about the state of other picos, they were not directly changing it. This time, each pico directly affects the violation_log of every other pico in the network, which is where the consensus comes from.

### 4. Is it possible for a node to issue two positive threshold violation messages (i.e. value = 1) without an intervening negative threshold violation messages (i.e. value = -1)? Justify your analysis. What are the consequences of such a scenario?  
Not on my system, because as soon as a new temperature is received, the system's state changes to reflect whether it's in "violation mode", and if it was in violation mode before and after a new temperature was received, it reverts back to zero. That way, the messages are always accurate. You could end up with values that are negative or overly positive (more than the total amount of picos in the network).

### 5. How does gossip messaging combined with CRDT compare with Paxos? Consider the threshold counter we implemented for this lab. How would it be different if you tried to use Paxos to implement it? 
They all strive to achieve consensus independently. If I remember correctly, Paxos would require each entitiy to share an absolute value for violation_counter, instead of a value to be added or subtracted from in another entity.  

### 6. How does gossip messaging combined with CRDT compare with Byzantine consensus (like in a blockchain)? 
I think gossip messaging isn't immutable, whereas blockchain is, but both allow for all nodes in a network to have knowledge of each other and each other's data.