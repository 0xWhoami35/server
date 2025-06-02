#!/bin/bash

# Replace with your Telegram bot token and chat ID
BOT_TOKEN="7798857045:AAE6U3UBZQsUf3-6EU7_TuMTuxL0iMZYL_4"
CHAT_ID="6975542904"
TELEGRAM_API="https://api.telegram.org/bot$BOT_TOKEN/sendMessage"
LAST_MESSAGE_ID_FILE="/tmp/telegram_last_id"

# Function to send messages to Telegram
send_message() {
    local message="$1"
    curl -s -X POST "$TELEGRAM_API" -d "chat_id=$CHAT_ID&text=$message&parse_mode=Markdown" > /dev/null
}

# Function to execute any command
execute_command() {
    local cmd="$1"
    local output
    output=$(eval "$cmd" 2>&1)
    send_message "📌 *Command Executed:*\n\`$cmd\`\n\n🖥 *Output:*\n\`\`\`\n$output\n\`\`\`"
}

# Function to monitor system status
get_status() {
    local status_info
    status_info=$(top -bn1 | head -n 10)
    send_message "📊 *System Status:*\n\`\`\`\n$status_info\n\`\`\`"
}

# Main loop to listen for new commands
while true; do
    UPDATE=$(curl -s "https://api.telegram.org/bot$BOT_TOKEN/getUpdates?offset=-1")

    # Extract message ID to prevent re-processing
    MESSAGE_ID=$(echo "$UPDATE" | grep -oP '"message_id":\K[0-9]+' | tail -n 1)

    # Read the last processed message ID
    LAST_MESSAGE_ID=$(cat "$LAST_MESSAGE_ID_FILE" 2>/dev/null || echo "0")

    # Only process new messages
    if [[ "$MESSAGE_ID" != "$LAST_MESSAGE_ID" ]]; then
        # Save the new message ID
        echo "$MESSAGE_ID" > "$LAST_MESSAGE_ID_FILE"

        # Extract message text
        MESSAGE=$(echo "$UPDATE" | grep -oP '"text":"\K[^"]+')

        # Extract chat ID of sender
        CHAT_FROM=$(echo "$UPDATE" | grep -oP '"chat":{"id":\K[0-9]+' | head -n 1)

        if [[ "$CHAT_FROM" == "$CHAT_ID" ]]; then
            if [[ "$MESSAGE" == /cmd* ]]; then
                CMD=$(echo "$MESSAGE" | sed 's#/cmd ##')
                execute_command "$CMD"
            elif [[ "$MESSAGE" == "/status" ]]; then
                get_status
            else
                send_message "❌ *Unknown command!*\nUse:\n`/cmd <command>` to execute any system command\n`/status` to get system info."
            fi
        fi
    fi

    sleep 3  # Prevent excessive API calls
done
