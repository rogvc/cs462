ruleset com.twilio.api {
  meta {
    name "Twilio API"
    configure using
      sid = ""
      auth_token = ""
    provides sendMessage, byu
  }

  global {

    base_url = "https://api.twilio.com"
    byu = function() {
      response = http:get("https://byu.edu")
      response{"content"}.decode()
    }
    sendMessage = defaction(recipient, sender, message) {
      auth_string = <<#{sid}: #{auth_token}>>
      http:post(<<#{base_url}/2010-04-01/Accounts/#{sid}/Messages.json>>,form = {"To": recipient,"From": sender, "Body": message},auth = auth_string) setting(response)
      return response
    }
  }

  rule test_send {
    select when test send_a_message
    pre {
      recipient = event:attrs{"To"}
      sender = event:attrs{"From"}
      message = event:attrs{"Message"}
    }
    if recipient && sender && message then
      sendMessage(recipient, sender, message)
  }

}
