#!/bin/bash

if [ -z $1 ]
	then 
		echo " Pas de paramètre "
		exit -1	
	fi
clear

IpCible=$1
Moi="Moi -- "

NomFichier="$(echo $IpCible | sed 's/\./\-/g').route"
echo -n  "$Moi" > $NomFichier
ttl=1
Hop=""
HopPlusUn=""
listArg=( "-U -p 1194" "-U -p 5060" "-U -p 5060" "-T -p 80" "-T -p 443" "-T -p 22"  "-I" )

#listArg=("")
# Premiere ligne 
for ttl in $(seq 1 30) 
	do
		for proto in "${listArg[@]}" 
			do 
				Hop=$(traceroute -f $ttl -m $ttl -q 1 $proto $IpCible -n |grep -v traceroute | cut -c 5- | cut -d " " -f 1  )
				HopPlusUn=$(traceroute -A -f $(($ttl+1)) -m $(($ttl+1)) -q 1 $proto $IpCible -n |grep -v traceroute | cut -c 5- | cut -d " " -f 1,2  )
			
				if [ "$Hop" == "$IpCible" ]
				then   
					echo -n  '"'" $Hop "'"'"; " >> $NomFichier
					break 2
				elif [ "$Hop" == "*" ] && [ "$proto" == "-I" ]
				then
					echo -n " Inconnue " >> $NomFichier
					echo -n " -- "'"' "Réseau avant $HopPlusUn & Réseau après $Hop"'"'" -- " >> $NomFichier
					break
				elif [ "$Hop" != "*" ] && [ "$Hop" != "$IpCible" ]
				then
					echo -n  '"'" $Hop "'"'  >> $NomFichier
					echo -n " -- "'"' "Réseau avant $HopPlusUn & Réseau après $Hop" '"'" -- " >> $NomFichier
					break
				fi
			done
	done

# Deuxieme ligne	
	echo "" >> $NomFichier
	for ttl2 in $(seq 1 $ttl)
		do	
			if [ "$ttl2" == "$ttl" ]
			then
				echo -n " $(cat $NomFichier |grep Moi | sed 's/ -- / -/g' | cut -d "-" -f $((($ttl2*2)+1)) )" >> test
			else

				echo -n " , $(cat $NomFichier |grep Moi | sed 's/ -- / -/g' |sed 's/;/ -/g' | cut -d "-" -f $((($ttl2*2)+1)) )" >> test
		fi
		done
	echo -n " [shape=ellipse,fontcolor=white];" >> test
	echo -n "$(cat test | sed -e 's/ /Moi /')" >> $NomFichier
	echo ""	>> $NomFichier
	rm test
