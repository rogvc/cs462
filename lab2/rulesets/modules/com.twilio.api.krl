ruleset com.twilio.api {
  meta {
    name "Twilio API"
    configure using
      sid = ""
      auth_token = ""
    provides sendMessage, messages
  }

  global {

    base_url = "https://api.twilio.com"
    
    messages = function (recipient = "", sender = "", page_size = "") {
      query_string = 
        {"To": recipient,"From": sender,"PageSize": page_size}
      response = http:get(
        <<https://#{sid}:#{auth_token}@api.twilio.com/2010-04-01/Accounts/#{sid}/Messages.json>>,
        qs = query_string
      )
      response{"content"}.decode()
    }

    sendMessage = defaction(recipient, sender, message) {
      http:post(
        <<https://#{sid}:#{auth_token}@api.twilio.com/2010-04-01/Accounts/#{sid}/Messages.json>>,
        form = {
          "To": recipient,
          "From": sender, 
          "Body": message
        }) setting(response)
    }
  }

  rule test_send_a_message {
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
