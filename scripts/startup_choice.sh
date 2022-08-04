#!/usr/bin/bash

cd /scripts || exit
PS3='Choose your mode: '
modes=("INTERACTIVE INSTALL" "BASE INSTALL" "MINIMAL INSTALL" "FULL INSTALL" "EXIT TO LIVE ISO")
select option in "${modes[@]}"; do
    case $option in
        "INTERACTIVE INSTALL")
            ./startup.sh
            exit
            ;;
        "BASE INSTALL")
            ./startup_with_answerfile.sh BASE
            exit
            ;;
        "MINIMAL INSTALL")
            ./startup_with_answerfile.sh MINIMAL
            exit
            ;;
	    "FULL INSTALL")
            ./startup_with_answerfile.sh FULL
            exit
	        ;;
	     "EXIT TO LIVE ISO")
	        echo "User requested exit"
	        break
	        ;;
         *) echo "Invalid option \"$REPLY\"; I don't have time for this!";;
    esac
done
