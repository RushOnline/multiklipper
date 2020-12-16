#!/bin/bash

instance_add() {
	echo "adding printer $1"
	CONFIG="/home/pi/klipper_config/printer$1.cfg"
	ID=$1
	MPORT=$(expr 7125 + $1)
	FPORT=$(expr 80 + $1)


	if ! [ -f $CONFIG ]; then
		echo "first create $CONFIG"
		exit 1
	fi

	if ! [ -f /etc/init.d/klipper ]; then
		echo "klipper not installed"
		exit 1
	fi

	if ! [ -f /etc/init.d/moonraker ]; then
		echo "moonraker not installed"
		exit 1
	fi

	sed \
		-e "s|/etc/default/klipper|/etc/default/klipper$1|g" \
		-e "s|/var/run/klipper.pid|/var/run/klipper$1.pid|g" \
		-e "s|NAME=\"klipper\"|NAME=\"klipper$1\"|g" \
		/etc/init.d/klipper > /etc/init.d/klipper$1
	chmod +x /etc/init.d/klipper$1

	sed \
		-e "s|printer.cfg|printer$1.cfg|g" \
		-e "s|klippy.log|klippy$1.log -I /tmp/printer$1|g" \
		-e "s|klippy_uds|klippy$1_uds|g" \
		/etc/default/klipper > /etc/default/klipper$1

	sed \
		-e "s|NAME=\"moonraker\"|NAME=\"moonraker$1\"|g" \
		-e "s|default/moonraker|default/moonraker$1|g" \
		-e "s|moonraker.pid|moonraker$1.pid|g" \
		/etc/init.d/moonraker > /etc/init.d/moonraker$1
	chmod +x /etc/init.d/moonraker$1

	sed \
		-e "s|moonraker.conf|moonraker$1.conf|g" \
		/etc/default/moonraker > /etc/default/moonraker$1

	sed \
		-e "s|7125|$MPORT|g" \
		/home/pi/moonraker.conf > /home/pi/moonraker$1.conf
	chown pi:pi /home/pi/moonraker$1.conf

	systemctl daemon-reload
	systemctl start klipper$1
	systemctl start moonraker$1

	cp -R /home/pi/fluidd /home/pi/fluidd$1
	sed \
		-e "s|7125|$MPORT|g" \
		/home/pi/fluidd/config.json > /home/pi/fluidd$1/config.json

	sed \
		-e "s|#ID#|$1|g" \
		-e "s|#FPORT#|$FPORT|g" \
		-e "s|#MPORT#|$MPORT|g" \
		fluidd.template > /etc/nginx/sites-enabled/fluidd$1

	systemctl reload nginx


}

instance_rm() {
	echo "removing printer $1"

	systemctl stop moonraker$1
	systemctl stop klipper$1

	echo rm /etc/default/moonraker$1
	echo rm /etc/default/klipper$1
	echo rm /etc/init.d/klipper$1
	echo rm /etc/init.d/moonraker$1

	systemctl daemon-reload

}

if [ -z "$2" ]; then
	$0 help usage
	exit 1
fi

case $1 in
add)
	instance_add $2
	;;
rm)
	instance_rm $2
	;;
*)
	echo "usage: $0 <add|rm> <number>"
	;;
esac
