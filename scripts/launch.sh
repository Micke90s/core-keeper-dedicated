#!/bin/bash

# Switch to workdir
cd "${STEAMAPPDIR}" || exit

### Function for gracefully shutdown
function kill_corekeeperserver {
    if [[ -n "$ckpid" ]]; then
        kill $ckpid
        wait $ckpid
    fi
    if [[ -n "$xvfbpid" ]]; then
        kill $xvfbpid
        wait $xvfbpid
    fi
}

trap kill_corekeeperserver EXIT

if [ -f "GameID.txt" ]; then rm GameID.txt; fi

# Compile Parameters
# Populates `params` array with parameters.
# Creates `logfile` var with log file path.
source "${SCRIPTSDIR}/compile-parameters.sh"

# Create the log file and folder.
mkdir -p "${STEAMAPPDIR}/logs"
touch "$logfile"

# Start Xvfb
Xvfb :99 -screen 0 1x1x24 -nolisten tcp &
xvfbpid=$!

# Start Core Keeper Server
DISPLAY=:99 LD_LIBRARY_PATH="${LD_LIBRARY_PATH}:${STEAMCMDDIR}/linux64/" ./CoreKeeperServer "${params[@]}" &
ckpid=$!

echo "Started server process with pid ${ckpid}"

tail --pid "$ckpid" -n +1 -f "$logfile" &

until [ -f GameID.txt ]; do
    sleep 0.1
done

gameid=$(<GameID.txt)
if [ -z "$DISCORD_HOOK" ]; then
    echo "Please set DISCORD_WEBHOOK url."
else
    echo "Discord gameid"
    format="${DISCORD_PRINTF_STR:-%s}"
    curl -i -H "Accept: application/json" -H "Content-Type:application/json" -X POST --data "{\"content\": \"$(printf "${format}" "${gameid}")\"}" "${DISCORD_HOOK}"

    # Monitor server logs for player join/leave
    tail -f CoreKeeperServerLog.txt | while read LOGLINE; do
        # Add timestamp to each log line
        echo "$(date '+%Y-%m-%d %H:%M:%S') - $LOGLINE"

        # Detect player join based on log: [userid:12345] is using new name PlayerName
        if echo "$LOGLINE" | grep -q "is using new name"; then
            PLAYER_NAME=$(echo "$LOGLINE" | grep -oP "is using new name \K\w+")
            echo "Player Name: $PLAYER_NAME" # Debugging: ensure player name is correct
            if [ -n "$PLAYER_NAME" ]; then
                WELCOME_MSG=$(echo "${DISCORD_MESSAGE_WELCOME:-'Welcome, \$\$user!'}" | sed "s/\$\$user/$PLAYER_NAME/g")
                echo "Generated Welcome Message: $WELCOME_MSG" # Debugging: ensure message is correct

                # Check if WELCOME_MSG is empty before sending
                if [ -z "$WELCOME_MSG" ]; then
                    echo "Error: Welcome message is empty"
                else
                    curl -i -H "Accept: application/json" -H "Content-Type: application/json" -X POST --data "{\"content\": \"$(printf "${format}" "${WELCOME_MSG}")\"}" "${DISCORD_HOOK}"
                fi
            fi
        fi

        # Detect potential player leave
        if echo "$LOGLINE" | grep -q "Accepted connection from .* with result OK awaiting authentication"; then
            PLAYER_NAME=$(echo "$LOGLINE" | grep -oP "Connected to userid:.*")
            if [ -n "$PLAYER_NAME" ]; then
                BYE_MSG=$(echo "${DISCORD_MESSAGE_BYE:-'Goodbye, $$user!'}" | sed "s/\$\$user/$PLAYER_NAME/g")
                echo "Generated Bye Message: $BYE_MSG" # Debugging: ensure message is correct

                # Check if BYE_MSG is empty before sending
                if [ -z "$BYE_MSG" ]; then
                    echo "Error: Bye message is empty"
                else
                    curl -i -H "Accept: application/json" -H "Content-Type: application/json" -X POST --data "{\"content\": \"$(printf "${format}" "${BYE_MSG}")\"}" "${DISCORD_HOOK}"
                fi
            fi
        fi
    done
fi

wait $ckpid
