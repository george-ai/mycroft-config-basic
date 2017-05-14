#!/bin/bash
##########################################################################
# startup_auto_run.sh
##########################################################################
# This script is executed by the .bashrc every time someone logs in to the
# system.

# Make sure the output is being output via the correct device.  You can
# change this to match your usage, the default is to output from the
# headphone jack.
#
sudo amixer cset numid=3 "1"   # audio out the analog speaker/headphone jack
#sudo amixer cset numid=3 "2"  # audio out the HDMI port (e.g. TV speakers)

amixer set Master 75% # set volume to a reasonable level


######################
# Comamnd line helpers
export PATH="$HOME/bin:$PATH"

echo "***********************************************************************"
echo "** Picroft development image, v0.8b                                  **"
echo "***********************************************************************"
echo "This image is designed to make getting started with Mycroft easy.  It"
echo "is pre-configured for a Raspberry Pi that has a speaker or headphones"
echo "plugged in to the Pi's headphone jack, and a USB microphone."
echo "***********************************************************************"

if [ "$SSH_CLIENT" == "" ]
then
   # running at the local console (e.g. plugged into the HDMI output)

   # First, force an upgrade if one is available
#   if ping -q -c 1 -W 1 google.com >/dev/null 2>&1
#   then
#      echo "Checking for updates to Mycroft..."
#      sudo apt-get update -o Dir::Etc::sourcelist="sources.list.d/repo.mycroft.ai.list" \
#                     -o Dir::Etc::sourceparts="-" -o APT::Get::List-Cleanup="0"
#      sudo apt-get install --only-upgrade mycroft-core mimic -y
#   fi
#   echo ""
   echo "========================================"
   python -c "import mycroft.version; print 'Mycroft Core Version: '+mycroft.version.CORE_VERSION_STR"
   echo "========================================"


   # TODO: I am not sure why the following is needed, but things don't start
   #       correctly without this restart workaround.
   echo "Starting up services"
   sleep 10
   sudo service mycroft-speech-client restart
   sleep 5

   # check to see if the unit is connected to the internet.
   if ! ping -q -c 1 -W 1 google.com >/dev/null 2>&1
   then
      echo "Internet connection not detected, starting WIFI setup process..."
      source configure_wifi.sh &

      # Wait for an internet connection -- either the user finished Wifi Setup or
      # plugged in a network cable.
      while ! ping -q -c 1 -W 1 8.8.8.8 >/dev/null 2>&1 ; do
          sleep 1
      done

      echo "Internet connection detected!"
      echo "Restarting..."
      sudo reboot now
   fi


   # check to see if the unit has been registered yet
   IDENTITY_FILE="/home/mycroft/.mycroft/identity/identity2.json"
   if [ -f $IDENTITY_FILE ]
   then
       IDENTITY_FILE_SIZE=$(stat -c%s $IDENTITY_FILE)
   else
       IDENTITY_FILE_SIZE=0
   fi

   echo ""
   if [ $IDENTITY_FILE_SIZE -lt 100 ]
   then
      # this invokes the pairing process
      echo "This unit needs to be registered.  Use your computer or mobile device"
      echo "to browse to https://home.mycroft.ai and enter the pairing code"
      echo "displayed below."
      sleep 2
      say "pair my device" >/dev/null 2>&1 &
   else
      echo "Mycroft is currently running in the background, so you can say"
      echo "'Hey Mycroft' to activate it. Try saying 'Hey Mycroft, what time is it'"
      echo "to test the system."
   fi
else
   # running from a SSH session
   echo "Remote session"
fi


sleep 2
echo ""
echo "***********************************************************************"
echo "In a few moments you will see the contents of the speech log.  Hit"
echo "Ctrl+C to stop showing the log and return to the command line.  You will"
echo "still be able to speak to Mycroft after that, only the display of the"
echo "log will cease.  To see the live log again, type:"
echo "    view_log"
echo ""
echo "Additional commands you can use from the command line:"
echo "    msm - Mycroft Skills Manager, install new Skills from Github"
echo "    cli - command line client"
echo "    say - one-shot commands from the command line"
echo "    test_microphone - record and playback to test your microphone"
echo "***********************************************************************"
echo ""
echo ""
sleep 2
tail -f /var/log/mycroft-speech-client.log
