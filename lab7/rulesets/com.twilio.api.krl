ruleset com.twilio.api {
  meta {
    configure using
      sid = ""
      auth_token = ""
    provides sendMessage, messages
  }

  global {

    base_url = "https://api.twilio.com"
    // sid = ""
    // auth_token = ""    
    messages = function (recipient = null, sender = null, page_size = null) {
      query_string = 
         {"To": recipient || null, "From": sender || null, "PageSize": page_size || null}
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

  rule configure_api_auth {
    select when twilio configure

    pre {
      event_sid = event:attrs{"sid"}
      event_auth_token = event:attrs{"auth_token"}
    }

    always {
      sid = event_sid
      auth_token = event_auth_token
    }
  } 

}
