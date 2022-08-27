#!/usr/bin/bash

cd /scripts || exit
PS3='Choose your mode: '
modes=("INTERACTIVE INSTALL" "BASE INSTALL" "MINIMAL INSTALL" "FULL INSTALL" "EXIT TO LIVE ISO")
select option in "${modes[@]}"; do
    case $option in
        "INTERACTIVE INSTALL")
            ./startup.sh
            break
            ;;
        "BASE INSTALL")
            ./startup_with_answerfile.sh BASE
            break
            ;;
        "MINIMAL INSTALL")
            ./startup_with_answerfile.sh MINIMAL
            break
            ;;
	    "FULL INSTALL")
            ./startup_with_answerfile.sh FULL
            break
	        ;;
	     "EXIT TO LIVE ISO")
            cd /script || exit
            chmod u+x keymap.sh
            ./keymap.sh
            cd
	        echo "User requested exit"
	        break
	        ;;
         *) echo "Invalid option \"$REPLY\"; I don't have time for this!";;
    esac
done
