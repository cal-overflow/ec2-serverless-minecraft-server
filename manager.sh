#!/bin/bash

set -e

DOCKER_IMAGE="smarterservers/minecraft-java-server-monitor:v0.1.0"
SCREEN_NAME="server"
CRON_SCHEDULE="*/1 * * * *" # Visit http://crontab.guru for help interpreting cron expressions
CRON_INTERVAL=5

setup() {
  echo "Ensuring dependencies are installed and up to date"
  sudo apt-get update
  sudo apt-get upgrade -y

  if ! [ -x "$(command -v java)" ]; then 
    echo "Installing Java (17)"
    sudo apt-get install openjdk-17-jre-headless -y

    echo "Java (17) install complete"
  fi

  if ! [ -x "$(command -v docker)" ]; then 
    echo "Installing docker"
    sudo apt-get install docker.io -y
    sudo chmod 666 /var/run/docker.sock

    echo "Docker install complete"
  fi

  if ! [ -x "$(command -v ifconfig)" ]; then 
    echo "Installing network tools"
    sudo apt-get install net-tools

    echo "Network tools install complete"
  fi
}

startAutoShutdown() {
  IS_AUTO_SHUTDOWN_ENABLED=$(cat cron_enabled.txt)
  if [ "$IS_AUTO_SHUTDOWN_ENABLED" == "true" ]; then
    echo "${CRON_SCHEDULE} /home/ubuntu/manager.sh autoShutdown" > job
    crontab job
  else
    crontab -r
  fi
}

start() {
  mkdir server || true
  cd server

  if screen -list | grep -q "$SCREEN_NAME"; then
    echo "Detected server is already running"

    if cat currentVersion.txt | grep -q "${TARGET_VERSION}"; then
      echo "Target version "${TARGET_VERSION}" already installed."
      export IS_CURRENT_TARGET=true
    fi

    stopScreenAndJar
  fi

  if ! [ "${IS_CURRENT_TARGET}" = "true" ]; then
    rm -f server.jar

    echo "Downloading ${TARGET_VERSION} server jar"
    curl $SERVER_JAR_URL -o server.jar

    if [ ! -f ./server.properties ]; then
      echo "Generating base server files"
      echo eula=false > eula.txt # Ensure next line doesn't actually start the server
      java -Xmx1024M -Xms1024M -jar server.jar nogui # Generates base files and exits since eula=false
    fi

    echo eula=true > eula.txt
    sed -i "s/^enable-query=.*\$/enable-query=true/" server.properties

    echo "" > screen.logs # reset logs
    echo "${TARGET_VERSION}" > currentVersion.txt
  fi

  echo "Starting server"
  screen -dmS "$SCREEN_NAME" -L -Logfile screen.logs java -Xmx1024M -Xms1024M -jar server.jar nogui
}

stop() {
  if screen -list | grep -q "$SCREEN_NAME"; then
    stopScreenAndJar
  fi
}

stopScreenAndJar() {
  while screen -list | grep -q "$SCREEN_NAME"; do
    echo "Stopping server..."
    screen -S $SCREEN_NAME -X stuff 'say Shutting down\nstop\nexit\n'
    sleep 10
  done
  echo "Server stopped"
}

autoShutdown() {
  PRIVATE_IP_ADDRESS=$(hostname -I | awk '{print $1}')
  PORT=$(cat server/server.properties | grep "query.port" | cut -d "=" -f2)

  sudo chmod 666 /var/run/docker.sock
  docker run $DOCKER_IMAGE -h $PRIVATE_IP_ADDRESS -p PORT # returns non-zero code if there are active players

  if [ $? -eq 0 ]; then
    if [[ "$1" == "isRecursiveCall" ]]; then
      autoShutdown "isFinalRecursiveCall"
    elif [[ "$1" == "isFinalRecursiveCall" ]]; then
      stop
      sudo shutdown now
    fi

    sleep "${CRON_INTERVAL}m"
    autoShutdown "isRecursiveCall"
  fi
}


$1 "$@"
