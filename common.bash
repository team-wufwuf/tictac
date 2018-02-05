function ttt () {
    if [[ -f game ]]; then export CURRENT_GAME=$(cat - < game); fi;
    MY_ID=${2:-${MY_ID}}
    MY_IPNS=$(ipfs key list -l | grep $MY_ID | cut -d' ' -f1) 
    OLD_CURRENT_GAME=$CURRENT_GAME
    case $1 in 
	init)
	    CURRENT_OPPONENT=${3}
	    CURRENT_GAME=$(ruby bin/ttt.rb -i ${MY_ID} -o ${3})
	    ;;
	show)
	    ruby bin/ttt.rb -g $CURRENT_GAME
	    ;;
	play)
	    CURRENT_GAME=$(ruby bin/ttt.rb -i ${MY_ID} -g $CURRENT_GAME -m "$3")
	    if [[ $CURRENT_GAME ]]; then
		ipfs pubsub pub $MY_IPNS "$CURRENT_GAME"$'\n'
	    fi
	    ;;
	sub)
	    IPNS_ADDR=$(ipfs cat $OPPONENT | head -n1)
	    echo $IPNS_ADDR
	    ipfs pubsub sub $IPNS_ADDR | while read GAME; do
		CURRENT_GAME=$(ruby bin/ttt.rb -i ${MY_ID} -g $GAME)
		ruby bin/ttt.rb -g $CURRENT_GAME > game
	    done
    esac
    if [[ ! $CURRENT_GAME ]]; then
	CURRENT_GAME=$OLD_CURRENT_GAME
    fi
    export CURRENT_GAME
    export CURRENT_OPPONENT
    export IPFS_ID
}

