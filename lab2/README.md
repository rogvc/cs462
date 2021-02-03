# Lab 2

## Screencast:

[View Screencast on YouTube](https://youtu.be/DR-eDRLpiTg)

## Rulesets URLs:

[sms_sender.krl](https://raw.githubusercontent.com/rogvc/cs462/master/lab2/rulesets/sms_sender.krl)

[com.twilio.api.krl](https://raw.githubusercontent.com/rogvc/cs462/master/lab2/rulesets/modules/com.twilio.api.krl)

## 1. Why does this assignment ask you to create a function for messages but an action for sendind the SMS message? What's the difference?

In Krl, there is a syntatic distinction between read and write operations on the state of an application. Functions are similar to `GET` requests in **HTTP**, they are used to read data. Actions, however, are similar to `POST`, `PUT`, and `DELETE`, where they change the state of the data involved.

## 2. Why did we introduce the secrets for the Twilio module by configuring the rule that uses the module, rather than condiguring the module directly?

This makes the module reusable and independent, as far as the account the client is associated with is concerned. If I were to publish this module somewhere, or someone with an account different than mine were to use the Twilio module, they would simply have to configure the module to use their own keys and client secrets, rather than changing the module's code.
