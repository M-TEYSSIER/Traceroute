#!/bin/bash

#############################################################################################################
# Description:												    #
# Ce script a pour but de tracer le chemin d'un paquet et d'en créer un cartographie.			    #
# 													    #
# Le script pourra tracer la route du paquet avec differents protocoles et sur différents numéros de ports. #
#													    #
# Outils utilisés:  traceroute, xdot, cut, grep, sed.							    #
# 													    #
#############################################################################################################


# Cette boucle permet de vérifier la présence d'un argument.  
if [ -z $1 ]						      
	then 						      
		echo " Pas de paramètre "		      
		
		exit -1
	fi						      
clear

tshark -a duration:5 -Y icmp host $1 > test | ping $1 -c 3
Moi="$(cat test| cut -c 4-| head -n 1 | cut -d " " -f 6)"
echo $Moi
rm test


# La variable "IpCible" permet de definir dans cette variable la valeur indiqué dans la commande excecuté.
IpCible=$1

# La variable "Moi" à pour but d'afficher l'origine du le paquet.


# La commande "NomFichier" permet de générer un ficher pour nom l'adresse IP ciblé en argument avec la spécificité ".route" pour xdot
NomFichier="$(echo $IpCible | sed 's/\./\-/g').route"

# Permet de rediriger le flux de la variable "Moi" dans le fichier généré par la variable "NomFichier".
echo -n  '"'"$Moi"'"' "-- " > $NomFichier

# Initialisation des variable "ttl", "Hop", "HopPlusUn".
ttl=1
Hop=""
HopPlusUn=""

# La liste "listArg" contient les differentes combinaisons de protocoles et ports.
listArg=( "-I" "-U -p 1194" "-U -p 5060" "-T -p 80" "-T -p 443" "-T -p 22" )


# Première ligne: affiche le parcours du paquet envoyer avec differents protocoles. Les adresses IP des sauts s'affichera tant que possible.

#Boucle permettant de compter le nombre de "ttl" du paquet (qui sera limité à 30).
for ttl in $(seq 1 30)  
	do
#		Boucle qui change de champs dans le tableau 'listArg', donc qui change les paramètres de protocoles et du n° de port.
		for proto in "${listArg[@]}" 
			do 
#				La variable "Hop" permet de récuperer sur l'excecution de la commande traceroute, avec la valeur de "ttl", l'adresse IP du saut.
#				
				Hop=$(traceroute -f $ttl -m $ttl -q 1 $proto $IpCible -n |grep -v traceroute | cut -c 5- | cut -d " " -f 1  )
				HopPlusUn=$(traceroute -A -f $(($ttl+1)) -m $(($ttl+1)) -q 1 $proto $IpCible -n |grep -v traceroute | cut -c 5- | cut -d " " -f 1,2  )
			
				if [ "$Hop" == "$IpCible" ]
				then   
					echo -n  '"'" $Hop "'"'"; " >> $NomFichier
					break 2
				elif [ "$Hop" == "*" ] && [ "$proto" == "-I" ] && [ "$HopPlusUn" == "*" ]
				then
					echo -n " Inconnuedesaut$ttl" >> $NomFichier
					echo -n " -- "'"' "Inconnue de saut $ttl" '"'" -- " >> $NomFichier
					break
				elif [ "$Hop" == "*" ] && [ "$proto" == "-I" ] && [ "$HopPlusUn" != "*" ]
				then
					echo -n " Inconnue " >> $NomFichier
					echo -n " -- "'"' "Réseau avant $HopPlusUn & saut $ttl" '"'" -- " >> $NomFichier
					break
				elif [ "$Hop" != "*" ] && [ "$Hop" != "$IpCible" ]
				then
					echo -n  '"'" $Hop "'"'  >> $NomFichier
					echo -n " -- "'"' "Réseau avant $HopPlusUn & saut $ttl" '"'" -- " >> $NomFichier
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
				echo -n " $(cat $NomFichier |grep $Moi | sed 's/ -- / -/g' | cut -d "-" -f $((($ttl2*2)+1)) )" >> test
			else

				echo -n " , $(cat $NomFichier |grep $Moi | sed 's/ -- / -/g' |sed 's/;/ -/g' | cut -d "-" -f $((($ttl2*2)+1)) )" >> test
		fi
		done
	echo -n " [shape=ellipse,fontcolor=white];" >> test
	echo -n "$(cat test | sed -e 's/ /"'$Moi'" /')" >> $NomFichier
	echo ""	>> $NomFichier
	echo "$(cat $NomFichier | sed 's/'[*]'/[65535]/g')" > $NomFichier
	rm test
