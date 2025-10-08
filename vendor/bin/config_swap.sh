    #! /vendor/bin/sh

    SWAP_FILE="/data/vendor/swap/swapfile"
    swapoptionstr=$1
    swapsizestr=$2
    modifystr=$3
    echo "swapoption is ${swapoptionstr}"
    echo "swapsize is ${swapsizestr}"

    case ${modifystr} in
            "1")
                  swapoff ${SWAP_FILE}
                  rm ${SWAP_FILE}
                    ;;
            *)
                      ;;

    esac

    case ${swapoptionstr} in
            "1")
                  swapoption=1
                    ;;
            "0")
                  swapoption=0
                     ;;
            *)
                      ;;

    esac
    case ${swapsizestr} in
            "1")
                    swapsize=1024
                   ;;
            "2")
                    swapsize=2048
                    ;;
            "3")
                    swapsize=3072
                    ;;
            "4")
                    swapsize=4096
                    ;;
            "5")
                    swapsize=5120
                    ;;
            "6")
                    swapsize=6144
                    ;;
            "7")
                    swapsize=7168
                    ;;
            "8")
                    swapsize=8192
                    ;;
            "9")
                    swapsize=9216
                    ;;
            "10")
                    swapsize=10240
                    ;;
            "11")
                    swapsize=11264
                    ;;
            "12")
                    swapsize=12288
                    ;;
            *)
                    ;;
    esac

    if [ ${swapoption} -eq 1 ];then
        if [ ! -f ${SWAP_FILE} ];then
                dd if=/dev/zero of=${SWAP_FILE} bs=1m count=${swapsize}
                mkswap ${SWAP_FILE}
                swapon ${SWAP_FILE} -p 32765
        else
                swapoff ${SWAP_FILE}
                swapon ${SWAP_FILE} -p 32765
        fi
    else
        swapoff ${SWAP_FILE}
        rm ${SWAP_FILE}

    fi
