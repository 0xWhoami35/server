#!/usr/bin/perl

use strict;
use warnings;
use LWP::UserAgent;
use File::Slurp;

# Replace with your Telegram bot token and chat ID
my $BOT_TOKEN = "7798857045:AAE6U3UBZQsUf3-6EU7_TuMTuxL0iMZYL_4";
my $CHAT_ID = "6975542904";
my $TELEGRAM_API = "https://api.telegram.org/bot$BOT_TOKEN/sendMessage";
my $LAST_MESSAGE_ID_FILE = "/tmp/telegram_last_id";

# Create a user agent for HTTP requests
my $ua = LWP::UserAgent->new;

# Function to send messages to Telegram
sub send_message {
    my ($message) = @_;
    $ua->post($TELEGRAM_API, {
        chat_id => $CHAT_ID,
        text => $message,
        parse_mode => 'Markdown'
    });
}

# Function to execute any command
sub execute_command {
    my ($cmd) = @_;
    my $output = `$cmd 2>&1`;
    send_message("📌 *Command Executed:*\n\`$cmd\`\n\n🖥 *Output:*\n\`\`\`\n$output\n\`\`\`");
}

# Function to monitor system status
sub get_status {
    my $status_info = `top -bn1 | head -n 10`;
    send_message("📊 *System Status:*\n\`\`\`\n$status_info\n\`\`\`");
}

# Main loop to listen for new commands
my $last_message_id = 0;
if (-e $LAST_MESSAGE_ID_FILE) {
    $last_message_id = read_file($LAST_MESSAGE_ID_FILE);
    chomp($last_message_id);
}

while (1) {
    my $update = $ua->get("https://api.telegram.org/bot$BOT_TOKEN/getUpdates?offset=-1")->decoded_content;
    
    # Extract message ID to prevent re-processing
    my ($message_id) = $update =~ /"message_id":(\d+)/;
    
    # Only process new messages
    if (defined $message_id && $message_id != $last_message_id) {
        # Save the new message ID
        write_file($LAST_MESSAGE_ID_FILE, $message_id);
        $last_message_id = $message_id;
        
        # Extract message text
        my ($message) = $update =~ /"text":"([^"]+)"/;
        
        # Extract chat ID of sender
        my ($chat_from) = $update =~ /"chat":{"id":(\d+)/;
        
        if (defined $chat_from && $chat_from == $CHAT_ID) {
            if (defined $message) {
                if ($message =~ /^\/cmd (.*)/) {
                    my $cmd = $1;
                    execute_command($cmd);
                } 
                elsif ($message eq "/status") {
                    get_status();
                } 
                else {
                    send_message("❌ *Unknown command!*\nUse:\n`/cmd <command>` to execute any system command\n`/status` to get system info.");
                }
            }
        }
    }
    
    sleep 3;  # Prevent excessive API calls
}
