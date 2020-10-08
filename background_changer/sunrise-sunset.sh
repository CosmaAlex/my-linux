#!/bin/bash

RETRY_INTERVAL_SECONDS=10
DAY_IMAGES=8
NIGHT_IMAGES=4

url="http://www.datameteo.com/meteo/weather_Lecce"
wallpapers_folder="/home/cosma/wallpapers/"
wallpapers_extension=".jpeg"

while [ 1 -eq 1 ] ; do

    # we get all the web page
    allfile=$( wget -qO-  $url | sed 's/<br/\n/g' | sed 's/<\/span>/\n/g' | grep -i ">Sunrise");
    if [ -z "$allfile" ] ; then
        # Connection is not available
        notify-send -t 5000 -i /home/cosma/.scripts/wall-notify.png "Dynamic Wallpaper" "Internet Connection is not available at the moment for sunrise information\nRetrying in $RETRY_INTERVAL_SECONDS seconds..."
        sleep $RETRY_INTERVAL_SECONDS
        continue
    fi

    # we get the original sunrise/sunset time values
    sunrise_str=$(echo $allfile | cut -d ":" -f 2,3 | sed 's|[^0-9]*\([0-9\:]*\)|\1 |g')
    sunset_str=$(echo $allfile | cut -d ":" -f 4,5 | sed 's|[^0-9]*\([0-9\:]*\)|\1 |g')

    # we convert time values to seconds since 1970
    sunrise=$(date --date="$sunrise_str" +%s)
    sunset=$(date --date="$sunset_str" +%s)
    let sunset_before=sunset-86400

    let day_seconds=sunset-sunrise
    let night_seconds=sunrise-sunset_before
    let day_interval=day_seconds/DAY_IMAGES
    let night_interval=night_seconds/NIGHT_IMAGES
    img_index=0
    tts=0

    actual_seconds=$(date +%s)
    if [ $actual_seconds -lt $sunrise ] || [ $actual_seconds -gt $sunset ] ; then
        seconds_since_sunset=0
        if [ $actual_seconds -lt $sunrise ] ; then
            let seconds_since_sunset=actual_seconds-sunset_before
        else
            let seconds_since_sunset=actual_seconds-sunset
        fi
        let img_index=(seconds_since_sunset*NIGHT_IMAGES)/night_seconds+1+DAY_IMAGES
        let tts=(seconds_since_sunset%night_interval)-night_interval
    else
        let seconds_since_sunrise=actual_seconds-sunrise
        let img_index=(seconds_since_sunrise*DAY_IMAGES)/day_seconds+1
        let tts=(seconds_since_sunrise%day_interval)-day_interval
    fi

    let tts=-tts+60
    xfconf-query --channel xfce4-desktop --property /backdrop/screen0/monitorHDMI-2/workspace0/last-image --set "$wallpapers_folder$img_index$wallpapers_extension"
    xfconf-query --channel xfce4-desktop --property /backdrop/screen0/monitoreDP-1/workspace0/last-image --set "$wallpapers_folder$img_index$wallpapers_extension"
    sleep $tts
done
