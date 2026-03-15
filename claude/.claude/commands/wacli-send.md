# Send WhatsApp Message

Send a text message via WhatsApp using wacli.

## Variables

to: $1 (phone number in international format, e.g., +41791234567)
message: $2 (the message text to send)

## Instructions

- Use wacli to send a text message to the specified phone number
- The phone number should be in international format (e.g., +41791234567)
- If the user provides a contact name instead of a number, ask them to provide the phone number
- The message will be sent immediately
- wacli must be authenticated first (run `wacli auth` if not already authenticated)

## Run

```bash
wacli send text --to "$to" --message "$message"
```

## Report

Confirm the message was sent successfully, or report any errors encountered.
