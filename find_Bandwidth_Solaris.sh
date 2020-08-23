#!/bin/bash
usage(){
echo "Usage: $0 [-i INTERFACE] [-s INTERVAL] [-c COUNT]"
echo
echo "-i INTERFACE"
echo "    The interface to monitor, default is eth0."
echo "-s INTERVAL"
echo "    The time to wait in seconds between measurements, default is 3 seconds."
echo "-c COUNT"
echo "    The number of times to measure, default is 10 times."
exit 3
}
readargs(){
while [ "$#" -gt 0 ] ; do
  case "$1" in
   -i)
    if [ "$2" ] ; then
     interface="$2"
     shift ; shift
    else
     echo "Missing a value for $1."
     echo
     shift
     usage
    fi
   ;;
   -s)
    if [ "$2" ] ; then
     sleep="$2"
     shift ; shift
    else
     echo "Missing a value for $1."
     echo
     shift
     usage
    fi
   ;;
   -c)
    if [ "$2" ] ; then
     counter="$2"
     shift ; shift
    else
     echo "Missing a value for $1."
     echo
     shift
     usage
    fi
   ;;
   *)
    echo "Unknown option $1."
    echo
    shift
    usage
   ;;
  esac
done
}
checkargs(){
if [ ! "$interface" ] ; then
  interface="eth0"
fi
if [ ! "$sleep" ] ; then
  sleep="3"
fi
if [ ! "$counter" ] ; then
  counter="10"
fi
}
printrxbytes(){
/usr/sbin/dladm show-link -s "$interface" | grep "$interface" | awk '{ print $3 }'
}
printtxbytes(){
/usr/sbin/dladm show-link -s "$interface" | grep "$interface" | awk '{ print $6 }'
}
bytestohumanreadable(){
multiplier="0"
number="$1"
while [ "$number" -ge 1024 ] ; do
  multiplier=$(($multiplier+1))
  number=$(($number/1024))
done
case "$multiplier" in
  1)
   echo "$number Kb"
  ;;
  2)
   echo "$number Mb"
  ;;
  3)
   echo "$number Gb"
  ;;
  4)
   echo "$number Tb"
  ;;
  *)
   echo "$1 b"
  ;;
esac
}

printresults(){
while [ "$counter" -ge 0 ] ; do
  counter=$(($counter - 1))
  if [ "$rxbytes" ] ; then
   oldrxbytes="$rxbytes"
   echo "oldrxbytes" $oldrxbytes
   oldtxbytes="$txbytes"
   echo "oldtxbytes" $oldtxbytes
  fi
  rxbytes=$(printrxbytes)
  echo "rxbytes" $rxbytes
  txbytes=$(printtxbytes)
  echo "txbytes" $txbytes
  if [ "$oldrxbytes" -a "$rxbytes" -a "$oldtxbytes" -a "$txbytes" ] ; then
   echo "RXbits = $(bytestohumanreadable $((8*$rxbytes - 8*$oldrxbytes))) TXbits = $(bytestohumanreadable $((8*$txbytes - 8*$oldtxbytes)))"
  else
   echo "Monitoring $interface every $sleep seconds. (RXbyte total = $(bytestohumanreadable $rxbytes) TXbytes total = $(bytestohumanreadable $txbytes))"
  fi
  sleep "$sleep"
done
}
readargs "$@"
checkargs
printresults
