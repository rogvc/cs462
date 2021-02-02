ruleset sms_sender {
  meta {
    use module com.twilio.api alias twilio
      with
        sid = meta:rulesetConfig{"sid"}
        auth_token = meta:rulesetConfig{"auth_token"}
    
    shares get_messages
  }

  global {
    get_messages = function (recipient = "", sender = "", page_size = "") {
      twilio:messages(recipient, sender, page_size)
    }
  }

  rule send_message {
    select when sms_sender send_message
    pre {
      recipient = event:attrs{"to"}.klog("recipient")
      sender = event:attrs{"from"}.klog("sender")
      message = event:attrs{"message"}.klog("message")
    }
    if recipient && sender && message then
      twilio:sendMessage(recipient, sender, message) setting(response)
    fired {
      raise sms_sender event "message_sent" attributes event:attrs
    }
  }
}