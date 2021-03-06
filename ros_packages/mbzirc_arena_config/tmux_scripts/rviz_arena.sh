#!/bin/bash
### BEGIN INIT INFO
# Provides: tmux
# Required-Start:    $local_fs $network dbus
# Required-Stop:     $local_fs $network
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: start the uav
### END INIT INFO
if [ "$(id -u)" == "0" ]; then
  exec sudo -u mrs "$0" "$@"
fi

# get path to script
SCRIPT_PATH="$( cd "$(dirname "$0")" ; pwd -P )"

# source $HOME/.zshrc
source $HOME/.bashrc

PROJECT_NAME=rviz_arena

MAIN_DIR=~/"bag_files"

# following commands will be executed first, in each window
pre_input="export ATHAME_ENABLED=0; mkdir -p $MAIN_DIR/$PROJECT_NAME"

# define commands
# 'name' 'command'
input=(
  'roscore' 'roscore
'
  'ArenaPub' 'waitForRos; roslaunch mbzirc_arena_config arena_publisher.launch
'
  'Rviz' "waitForRos; rosrun rviz rviz -d ${SCRIPT_PATH}/../rviz/arena.rviz
"
  'KILL_ALL' 'dmesg; tmux kill-session -t '
)

init_window="ArenaPub"

###########################
### DO NOT MODIFY BELOW ###
###########################

SESSION_NAME=mav

# Absolute path to this script. /home/user/bin/foo.sh
SCRIPT=$(readlink -f $0)
# Absolute path this script is in. /home/user/bin
SCRIPTPATH=`dirname $SCRIPT`

if [ -z ${TMUX} ];
then
  TMUX= /usr/bin/tmux new-session -s "$SESSION_NAME" -d
  echo "Starting new session."
else
  echo "Already in tmux, leave it first."
  exit
fi

# get the iterator
ITERATOR_FILE="$MAIN_DIR/$PROJECT_NAME"/iterator.txt
if [ -e "$ITERATOR_FILE" ]
then
  ITERATOR=`cat "$ITERATOR_FILE"`
  ITERATOR=$(($ITERATOR+1))
else
  echo "iterator.txt does not exist, creating it"
  touch "$ITERATOR_FILE"
  ITERATOR="1"
fi
echo "$ITERATOR" > "$ITERATOR_FILE"

# create file for logging terminals' output
LOG_DIR="$MAIN_DIR/$PROJECT_NAME/"
SUFFIX=$(date +"%Y_%m_%d_%H_%M_%S")
SUBLOG_DIR="$LOG_DIR/"$ITERATOR"_"$SUFFIX""
TMUX_DIR="$SUBLOG_DIR/tmux"
mkdir -p "$SUBLOG_DIR"
mkdir -p "$TMUX_DIR"

# link the "latest" folder to the recently created one
rm "$LOG_DIR/latest"
rm "$MAIN_DIR/latest"
ln -sf "$SUBLOG_DIR" "$LOG_DIR/latest"
ln -sf "$SUBLOG_DIR" "$MAIN_DIR/latest"

# create arrays of names and commands
for ((i=0; i < ${#input[*]}; i++));
do
  ((i%2==0)) && names[$i/2]="${input[$i]}"
  ((i%2==1)) && cmds[$i/2]="${input[$i]}"
done

# run tmux windows
for ((i=0; i < ${#names[*]}; i++));
do
  /usr/bin/tmux new-window -t $SESSION_NAME:$(($i+1)) -n "${names[$i]}"
done

/usr/bin/tmux send-keys -t $SESSION_NAME:$((${#names[*]}+1)) "${pes}"

sleep 6

# start loggers
for ((i=0; i < ${#names[*]}; i++));
do
  /usr/bin/tmux pipe-pane -t $SESSION_NAME:$(($i+1)) -o "ts | cat >> $TMUX_DIR/$(($i+1))_${names[$i]}.log"
done

# send commands
for ((i=0; i < ${#cmds[*]}; i++));
do
  tmux send-keys -t $SESSION_NAME:$(($i+1)) "cd $SCRIPTPATH;${pre_input};${cmds[$i]}"
done

pes="sleep 1;"
for ((i=0; i < ((${#names[*]}+2)); i++));
do
  pes=$pes"/usr/bin/tmux select-window -t $SESSION_NAME:$(($i))"
  pes=$pes"/usr/bin/tmux resize-pane -U -t $(($i)) 150"
  pes=$pes"/usr/bin/tmux resize-pane -D -t $(($i)) 7"
done

# identify the index of the init window
init_index=0
for ((i=0; i < ((${#names[*]})); i++));
do
  if [ ${names[$i]} == "$init_window" ]; then
    init_index=$(expr $i + 1)
  fi
done

pes=$pes"/usr/bin/tmux select-window -t $SESSION_NAME:$init_index"

/usr/bin/tmux send-keys -t $SESSION_NAME:$((${#names[*]}+1)) "${pes}"

/usr/bin/tmux -2 attach-session -t $SESSION_NAME

clear
