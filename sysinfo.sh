#!/bin/bash
# config
FILE="$HOME/systemdata.log"
VERSION="20120618"
# parse switches
# hardware sound graphics network interactive pastebin version
while getopts 'hsgnipv' OPTION
do
	case $OPTION in
	v)	printf "%s v%s\n" $(basename $0) $VERSION
		exit 0;;
	i)	INTERACTIVE=true
		break;;
	h)	HARDWARE=true;;
	s)	SOUND=true;;
	g)	GRAPHICS=true;;
	n)	NETWORK=true;;
	p)	PASTEBIN=true;;
	?)	printf "Usage: %s: [-hsgnipv]\n" $(basename $0)
		exit 2;;
	esac
done

if [ "$(whoami)" = "root" ]; then
	ROOT=true
fi


# ignore other switches if in interactive mode
if [ $INTERACTIVE ]; then
	# Hardware information	
	echo -n "Hardware-Informationen sammeln? (J|n): "
	read TMP
	if [ "$TMP" = "n" ]; then
		HARDWARE=false
	else
		HARDWARE=true
	fi
	# Sound information
	echo -n "Sound-Informationen sammeln? (J|n): "
	read TMP
	if [ "$TMP" = "n" ]; then
		SOUND=false
	else
		SOUND=true
	fi
	# Graphics
	echo -n "Grafik-Informationen sammeln? (J|n): "
	read TMP
	if [ "$TMP" = "n" ]; then
		GRAPHICS=false
	else
		GRAPHICS=true
	fi
	# Network
	echo -n "Netzwerk-Informationen sammeln? Achtung, hier können private Informationen enthalten sein! (J|n): "
	read TMP
	if [ "$TMP" = "n" ]; then
		NETWORK=false
	else
		NETWORK=true
	fi
	# Pastebin
	echo -n "Informationen nach dem Sammeln hochladen? (J|n): "
	read TMP
	if [ "$TMP" = "n" ]; then
		PASTEBIN=false
	else
		PASTEBIN=true
	fi
fi


# check if glxinfo is installed
command -v glxinfo &>/dev/null
if [ $? -eq 0 ]; then
	GLXINFO=true
fi
# same for pastebinit
command -v pastebinit &>/dev/null
if [ $? -eq 0 ]; then
	PASTEBINIT=true
fi

# prepare file
touch $FILE

# gather basic information
echo "[uname -a]" > $FILE
uname -a >> $FILE
echo "[lsb-release]" >> $FILE
lsb_release -a &> /dev/null >> $FILE
echo "[sources]" >> $FILE
cat /etc/apt/sources.list >> $FILE
ls /etc/apt/sources.list.d/ >> $FILE
echo "[groups]" >> $FILE
groups >> $FILE

# generic hardware information
if [ $HARDWARE ]; then
	if [ $ROOT ]; then
		echo "[lshw]" >> $FILE
		lshw >> $FILE
	else
		echo "[lsusb]" >> $FILE
		lsusb >> $FILE
		echo "[lspci]" >> $FILE
		lspci -knn >> $FILE
	fi
fi

# graphics related stuff
if [ $GRAPHICS ]; then
	echo "[glxinfo]" >> $FILE
	if [ $GLXINFO ]; then
		glxinfo >> $FILE
	fi
	echo "[xorg.conf]" >> $FILE
	ls /usr/share/X11/xorg.conf.d/ >> $FILE
	if [ -f /etc/X11/xorg.conf ]; then
		cat /etc/X11/xorg.conf >> $FILE
	fi
fi

# sound
if [ $SOUND ]; then
	echo "[pactl]" >> $FILE
	pactl -list >> $FILE
	echo "[/proc/asound/cards]" >> $FILE
	cat /proc/asound/cards >> $FILE
	echo "[soundserver]" >> $FILE
	ps -eF | egrep -i "esd|arts|pulseaudio|jack" >> $FILE
	echo "[/etc/asound.conf]" >> $FILE
	cat /etc/asound.conf >> $FILE
	echo "[asoundrc]" >> $FILE
	cat /home/$USER/.asoundrc* >> $FILE
	echo "[aplay -l]" >> $FILE 
	aplay -l >> $FILE
	echo "[aplay -L]" >> $FILE
	aplay -L >> $FILE
	echo "[soundmodule]" >> $FILE
	lsmod | grep "snd" >> $FILE
	echo "[audiocodec]" >> $FILE
	head -n 3 /proc/asound/card0/codec97#0/ac97#0-0* >> $FILE
	head -n 3 /proc/asound/card0/codec#0 >> $FILE
	echo "[asoundconf]" >> $FILE
	asoundconf list >> $FILE
	echo "[soundcheck]" >> $FILE
	aplay /usr/share/sounds/alsa/Front_Center.wav &>/dev/null &
	echo -n "Hast Du die Stimme gehört? (J|n): "
	read TMP
	if [ "$TMP" = "n" ]; then
		echo "failed" >> $FILE
	else
		echo "successful" >> $FILE
	fi
fi

# network
if [ $NETWORK ]; then
	echo "[ifconfig]" >> $FILE
	ifconfig -a >> $FILE
	echo "[netstat]" >> $FILE
	netstat -tulpen >> $FILE
	# do we need this?
	echo "[iwlist]" >> $FILE
	iwlist scan >> $FILE
fi

echo "ACHTUNG: Einige Logs können persönliche Daten enthalten, bitte überprüfe die Datei $FILE vor dem Abschicken."

if [ $PASTEBIN ]; then
	echo -en "Drücke eine beliebige Taste, um die Datei $FILE hochzuladen.\n"
	read -n 1 -s
	if [ $PASTEBINIT ]; then
		pastebinit $FILE
	else
		# error
		echo "Fehler: Konnte Datei nicht hochladen, da 'pastebinit' nicht installiert ist."
		exit 2
	fi
fi

# exit gracefully
exit 0

