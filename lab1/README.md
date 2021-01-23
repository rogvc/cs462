# Lab 1

## Screencast:

[Download screencast.mp4](https://github.com/rogvc/cs462/blob/master/lab1/resources/screencast.mp4?raw=true)

## Ruleset URL(s):
[hello_world.krl](https://raw.githubusercontent.com/rogvc/cs462/master/lab1/rulesets/hello_world.krl)

## 1. Send an event to the pico using the new channel and the original (default) channel. Do you get the same result on both? Why or why not?
I got different results.

The permissive channel I created (with `Event Policy allow *:*`) gave me a `200 OK` response, with a list of directives containing a description of the `Hello World` rule I created in Lab 0. 

![Response on Permissive Channel](https://github.com/rogvc/cs462/blob/master/lab1/resources/test_event_permissive_channel.png?raw=true)

The default channel gave me an error saying the operation was not allowed by the channel policy.

![Response on Default Channel](https://github.com/rogvc/cs462/blob/master/lab1/resources/test_event_engine_ui_channel.png?raw=true)

## 3. Delete the channel and resend the event using the deleted channel. What happens? Why?
I got an error saying that the ECI (Channel identifier) was not found.

![Response on Deleted Channel](https://github.com/rogvc/cs462/blob/master/lab1/resources/test_event_deleted_channel.png?raw=true)

## 4. Send the misspelled event ecco/hello to your pico. What do you observe? Why? 
I got a successful HTTP response (`200 OK` response code), with an empty list of directives.

I'm thinking this happened because the request was formatted correctly, using a channel that permitted the operation, but there was no event found that matched the request.

![Response of Misspelled Event on Permissive Channel](https://github.com/rogvc/cs462/blob/master/lab1/resources/test_misspelled_event_permissive_channel.png?raw=true)