ruleset manager_profile {
    meta {
        configure using
            sid = meta:rulesetConfig{"sid"}
            auth_token = meta:rulesetConfig{"auth_token"}
            notification_sender_number = meta:rulesetConfig{"notification_sender_number"}
            notification_recipient_number = meta:rulesetConfig{"notification_recipient_number"}
            temperature_threshold = meta:rulesetConfig{"temperature_threshold"}
        
        shares get_config
        provides get_config    
    }

    global {
        get_config = function () {
            {
                "sid": sid,
                "auth_token": auth_token,
                "notification_sender_number": notification_sender_number,
                "notification_recipient_number": notification_recipient_number,
                "temperature_threshold": temperature_threshold
            }
        }
    }
}