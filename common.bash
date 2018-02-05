function ttt () {
    MY_ID="$2"
    OLD_CURRENT_GAME=$CURRENT_GAME
    case $1 in 
	init)
	    CURRENT_GAME=$(ruby bin/ttt.rb -i ${MY_ID} -o ${3})
	    ;;
	play)
	    CURRENT_GAME=$(ruby bin/ttt.rb -i ${MY_ID} -g $CURRENT_GAME -m "$3")
    esac
    if [[ ! $CURRENT_GAME ]]; then
	CURRENT_GAME=$OLD_CURRENT_GAME
    fi
	  

}

