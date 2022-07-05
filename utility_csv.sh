#! /bin/bash
#
#
#

. ~/terminalcolor.sh
#. ~/ErrorHandling.sh

arrFields=""
arrTable=()

writeCsv()
{
	printf "\t${arrFields}\n"
	index=0
	for r in "${arrTable[@]}"
	do
		printf "${index}:\t${r}\n"
		((index++))
	done
}

inCsv()
{
	arrFields=$(head -n 1 $1)
	while IFS="," read -r row
	do
		arrTable+=("${row}")
	done < <(tail -n +2 $1)
	return 0
}

outCsv()
{
	printf "${arrField}\n" > $1
	for i in "${arrTable[@]}"
	do
		printf "${i}\n" >> $1
	done
	return 0
}

genCsv()
{
	t=0
	printf "Time,HVol,TVol\n" > test_001.csv
	for i in {1..24}
	do
		r=${RANDOM}
		t=$((t=t+r))
		if [ ${#i} -eq 1 ]
		then
			printf "0${i}00,${r},${t}\n" >> test_001.csv
		else
			printf "${i}00,${r},${t}\n" >> test_001.csv
		fi
	done
	return 0
}

#TerminalColors

#CommonUtils
throw()
{
	toConsole "30;101" "ERR[${?}]"
	toConsole "31" " ${0}[${LINENO}]-${FUNCNAME[1]}: ${*}\n" >&2
	exit 1
}

main()
{
	if [ -z $1 ]; then throw "Missing Src Csv"; fi
	if [ -z $2 ]; then throw "Missing Dst Csv"; fi
	genCsv
	inCsv $1
	writeCsv $1
	outCsv $2
}

main $1 $2
