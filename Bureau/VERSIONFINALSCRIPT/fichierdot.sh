#!/bin/sh

if [ -e map.dot ]
then
	rm map.dot
	touch map.dot
fi

cat header/debut.txt >> cat *.route >> cat header/fin.txt >> map.dot
xdot map.dot
