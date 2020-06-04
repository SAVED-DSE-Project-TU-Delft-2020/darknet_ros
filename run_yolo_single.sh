#!/bin/bash

printf "======================================================================\n"
printf "                        RUNNING YOLO ONE CHOICE                       \n"
printf "======================================================================\n\n"

# get useful paths
cd ..
git_head=$(readlink -f ./$(git rev-parse --show-cdup))

launch_location=$git_head/src/perception/darknet_ros/darknet_ros/launch
rosbag_location=$git_head/src/perception/video_to_ros/rosbags 

printf "Found rosbags:\n\n"

declare -a lst=()

for entry in "$rosbag_location"/*
do
  bag=${entry##*/}
  bag=${bag%.*}
  lst+="$bag "
done

select rosbag in $lst
do

echo "You have chosen $rosbag"

read -p $'\nPress [ENTER] to start YOLO performance collection \n' foo

printf "Running $rosbag ...\n"

{

# launch image streamer
roslaunch $launch_location/yolo_v3.launch & 

# start playing rosbag
rosbag play $rosbag_location/$rosbag.bag -l &

sleep 3

# start recording performance of detection
rostopic echo -p /darknet_ros/bounding_boxes > $git_head/src/perception/validation/performance_record/$rosbag-bb.csv &
rostopic echo -p /darknet_ros/found_object > $git_head/src/perception/validation/performance_record/$rosbag-fo.csv 

} &> /dev/null

printf "Collection completed ... \n\n"

done

# kill processes
killall -9 roscore
rosnode kill -a
cd darknet_ros




