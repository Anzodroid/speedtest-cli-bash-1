#!/bin/bash
PATH=/opt/bin:/opt/sbin:$PATH
git config --global user.email "anzodroid@gmail.com"
git config --global user.name "anzodroid"
git config --global credential.helper store 

# Set up variables
waitTime='60'
resultsFile='speedtestresults.txt'
CPUresultsFile='CPUtestresults.txt'
currentTime=$(date "+%Y-%m-%d %H:%M:%S")
BASEDIR=$(dirname $(readlink -f $0))
helpMessage='usage [-s save to file] [-g save to github] [-c record in csv] [-o run once] [-w wait time in seconds] [-r results file]'


# Get script arguments
while getopts sgcohw:r: opt;
do

case $opt in
    s)
        save=true;;
    g)
        github=true;;
    c)
        csv=true;;
    o)
        once=true;;
	w)
		waitTime="$OPTARG";;
	r)
		resultsFile="$OPTARG";;
    h)
        echo $helpMessage 
		exit 0;;
    \?)
		echo $helpMessage
        echo "Exiting due to illegal option" >&2
		exit 1;;
esac
sleep 1
done


# Loop run test and wait $waitTime between tests
while true
do

save() {
	echo "Saving to file $resultsFileFull"
	echo "Saving to file $CPUFileFull"
	if [ $csv ]
		then
		echo $results >> $resultsFileFull
		echo $results >> $CPUFileFull
	else
		echo $results | python -m json.tool >> $resultsFileFull
	fi
	echo "File saved"
}

resultsFileFull=$BASEDIR/$resultsFile
CPUFileFull=$BASEDIR/$CPUresultsFile
cd $BASEDIR
echo "Starting SpeedTest check at $currentTime"


if [ $csv ] 
then
    date
    cat /proc/loadavg 
    results=$(speedtest-cli --csv) 
    (date +"%F %T";  cat /proc/loadavg;) | tr '\n' -s | tr '-' ' '
    (date +"%F %T";  cat /proc/loadavg;) | tr '\n' -s | tr '-' ' '>> $CPUFileFull
    echo $results
else
    results=$(speedtest-cli --json)
    echo $results | python -m json.tool
fi
echo 'SpeedTest complete'


if [ $save ] 
then
	save
elif [ $github ] 
then
	save
    echo "Attempting git add, commit, & push to GitHub of $resultsFile"
        echo `git add $resultsFile`
        echo `git add $CPUresultsFile`
        echo `git commit $CPUresultsFile -m "CPU results updated at $currentTime"`
        echo `git commit $resultsFile -m "Speedtest results updated at $currentTime"`
        echo `git push origin master`
    echo "File pushed $resultsFileFull"
fi

if [ $once ] 
then
	echo "Job done!"
	break
fi

echo "Waiting $waitTime seconds until next test..."

sleep $(($waitTime * 10))

done
