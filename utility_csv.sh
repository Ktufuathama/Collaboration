#! /bin/bash
#
# WARNING!!!
#		CSV Alphanumeric Only! Not configured to handle quotes or special characters.
#

. ~/terminalcolor.sh

declare arrFields
declare -a arrTable
declare splitObj

# param
#		1: FilePath;
inCsv()
{
	arrTable=()
	arrFields=$(head -n 1 $1)
	while IFS="," read -r row; do
		arrTable+=("${row}")
	done < <(tail -n +2 $1)
	return 0
}

# param
#		1: FilePath;
outCsv()
{
	printf "${arrFields}\n" > $1
	for i in "${arrTable[@]}"; do
		printf "${i}\n" >> $1
	done
	return 0
}


writeCsv()
{
	printf "\t${arrFields}\n"
	index=0
	for r in "${arrTable[@]}"; do
		printf "${index}:\t${r}\n"
		((index++))
	done
}

# param
#		1: FilePath;
update()
{
	#GetCsv
	inCsv $1
	curDate=$(date '+%H%M')

	echo "DBG: 0"
	writeCsv
	
	for i in "${arrTable[@]}"; do
		echo "${i}"
		if [ $item -ge $((curDate - 30)) ] && [ $item -le $((curDate + 30)) ]; then
			echo "Match ${curDate}"
		else
			echo "NoMatch ${curDate}"
		fi
		echo ">> ${item}"
	done

	echo "DBG: 1"
	writeCsv
	
	return 0
}

# param
#		1: FilePath;
#		2: CurTimeToTest;
update2()
{
	inCsv $1
	if [ ! -z $2 ]; then
		curTime=$2
	else
		curTime=$(date '+%H%M')
	fi
	for i in "${arrTable[@]}"; do
		time=$(splitArr $i 0)

		echo $((${curTime#0} - 30))
		echo $((${curTime#0} + 30))
		
		#Get Entry within 30 mins.
		if [ $time -ge $((${curTime#0} - 30)) ] || [ $time -le $((${curTime#0} + 30)) ]; then
			printf "Match\t${curTime}:${time}\n"
		else
			printf "NoMatch\t${curTime}:${time}\n"
			continue
		fi
	done
}

mathTest()
{
	if [ $1 -gt $(($2 + 100)) ]; then
		echo "GT: ${1}|${2}"
	else
		echo "LT: ${1}|${2} - "
	fi
}

# param
#		1: FilePath;
genCsvNew()
{
	printf "Time,HVol,TVol\n" > $1
	for i in {1..24}; do
		if [ ${#i} -eq 1 ]; then
			printf "0${i}00,,\n" >> $1
		else
			printf "${i}00,,\n" >> $1
		fi
	done
	return 0
}

# param
#		1: FilePath;
genCsvRnd()
{
	t=0
	printf "Time,HVol,TVol\n" > $1
	for i in {1..24}; do
		r=${RANDOM}
		t=$((t=t+r))
		if [ ${#i} -eq 1 ]; then
			printf "0${i}00,${r},${t}\n" >> $1
		else
			printf "${i}00,${r},${t}\n" >> $1
		fi
	done
	return 0
}

isInitialized()
{
	if [ -z $arrFields ] || [ ${#arrTable[@]} -eq 0 ]; then
		echo "Status: Not Initialized"
		return 1
	else
		echo "Status: Initialized"
		return 0
	fi
}

# param
#		1: Object;
#		2: Index;
splitArr()
{
	while IFS="," read -ra row; do
		echo "${row[${2}]}"
		splitObj="${row[${2}]}"
	done <<< $1
}

#Common
throw()
{
	toConsole "30;101" "ERR[${?}]"
	toConsole "31" " ${0}[${LINENO}]-${FUNCNAME[1]}: ${*}\n" >&2
	exit 1
}

# param
#		1: FilePath Source;
#		2: FilePath Destination;
main()
{
	if [ -z $1 ]; then throw "Missing Src Csv"; fi
	if [ -z $2 ]; then throw "Missing Dst Csv"; fi
	genCsv $1
	inCsv $1
	writeCsv
	outCsv $2
}

#main $1 $2
