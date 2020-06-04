#!/bin/bash

printf "======================================================================\n"
printf "                        RUNNING YOLO                                  \n"
printf "======================================================================\n\n"

# get useful paths
cd ..
git_head=$(readlink -f ./$(git rev-parse --show-cdup))
launch_location=$git_head/src/perception/darknet_ros/darknet_ros/launch
rosbag_location=$git_head/src/perception/video_to_ros/rosbags 

# ask rosbag input
printf "Title of the recording: "
read title
printf "\nFPS of the recording: "
read fps
printf "\nDuration of each record: "
read duration

# collect rosbags from path
printf "\nFound rosbags:\n\n"

declare -a lst=()

for entry in "$rosbag_location"/*
do
  bag=${entry##*/}
  bag=${bag%.*}
  if [ "${bag%%-*}" = $title ]; then
    if [ "${bag##*-}" = $fps ]; then
      echo "$bag"
      lst+="$bag "
    fi;
  fi;
done

read -p $'\nPress [ENTER] to start YOLO performance collection \n' foo

# start collecting data for each rosbag

for rosbag in $lst
do 

  printf "Running $rosbag ...\n\n"

  {

  # launch image streamer
  roslaunch $launch_location/yolo_v3.launch & 

  # start playing rosbag
  rosbag play $rosbag_location/$rosbag.bag -l &

  sleep 3

  # start recording performance of detection
  rostopic echo -p /darknet_ros/bounding_boxes > $git_head/src/perception/validation/performance_record/$rosbag-bb.csv &
  rostopic echo -p /darknet_ros/found_object > $git_head/src/perception/validation/performance_record/$rosbag-fo.csv &

  sleep $duration

  # kill processes
  killall -9 roscore
  rosnode kill -a

  } &> /dev/null

done

printf "Collection completed ... \n\n"




