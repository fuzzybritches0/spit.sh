#!/bin/bash

render_funcs() {
	if [ "${SEQC}" == "0" ] || [ "${SEQC}" == "1" ]; then
		render_equation
	elif [ "${SEQC}" == "2" ]; then
		render_code
	#elif [ "${SEQC}" == "3" ]; then
	#	speak_text "${SPEAK}"
	else
		render_code2 LISTING
	fi
}

return_1() {
	echo "${1}"
}

espeak() {
	echo "${SEQ}" > "${SPEAKFIFO}"
}

speak_text() {
	echo -n "${SEQ}" | lowdown -tterm
	[ "${1}" ] && espeak "${SEQ}"
}

render_code2() {
	#echo -n ">2>${SEQ}<<<"
	[ "${SEQ:0:1}" == $'\n' ] && SEQ="${SEQ:1}"
	DISP="${STARTSEQS[${SEQC}]}"
	echo
	echo -n "* **${DISP:1:-1}**" | lowdown -tterm
	echo -n "${SEQ}" | \
	batcat --style numbers,grid --file-name "${1}" -f --paging=never
}

render_code() {
	#echo -n ">1>${SEQ}<<<"
	PL="$(return_1 ${SEQ})"
	if [ "${SEQ:0:1}" == $'\n' ]; then
		echo
		echo -n "* ***LISTING***" | lowdown -tterm
		echo -n "${SEQ:1}" | \
		batcat --style numbers,grid -f --paging=never
	elif [ "${SEQ:${#PL}:1}" == $'\n' ]; then
		echo
		echo -n "* ***${PL}***" | lowdown -tterm
		SEQ="${SEQ:1}"
		echo -n "${SEQ:${#PL}}" | \
		batcat --style numbers,grid -f --paging=never -l ${PL}
	else
		echo
		echo -n "* ***LISTING***" | lowdown -tterm
		echo -n "${SEQ}" | \
		batcat --style numbers,grid -f --paging=never
	fi
}

render_equation() {
	echo #-n ">>>${SEQ}<<<"
	mimetex -d -o -s 10 "${SEQ}" | img2sixel
	echo
}
NL=$'\n'
STARTSEQS=("\(" "\[" '```' "${NL}[SPEAK]" "<tool_response>")
STOPSEQS=("\)" "\]" '```' "[/SPEAK]" "</tool_response>")
BUFFS=27
FLIP=0
BUFF=
DELAY=0

SPEAKFIFO="./.speakfifo"
if [ "${1}" == "SPEAK" ]; then
	SPEAK=1
fi

[ -e "./spit.conf.sh" ] && . "./spit.conf.sh"
if [ "${STOP_SEQUENCES[0]}" ]; then
	((BUFFS-=4))
	for EACH in "${STOP_SEQUENCES[@]}"; do
		STARTSEQS+=("${NL}[${EACH}]")
		STOPSEQS+=("${NL}[/${EACH}]")
		[ "${#EACH}" -gt "${BUFFS}" ] && BUFFS="${#EACH}"
	done
	((BUFFS+=4))
fi

calc() {
	if [ "${FLIP}" == "1" ]; then
		STOPSEQL="${#STOPSEQS[${SEQC}]}"
		if [ "${BUFF:0:${STOPSEQL}}" == "${STOPSEQS[${SEQC}]}" ]; then
			FLIP="0"
			if [ "${SEQ}" ]; then
				SEQ="${SEQ:${STARTSEQL}}"
				render_funcs
				SEQ=
				((DELAY=${STOPSEQL}))
			fi
		fi
		SEQ="${SEQ}${BUFF:0:1}"
	else
		SEQC=0
		for STARTSEQ in "${STARTSEQS[@]}"; do
			STARTSEQL="${#STARTSEQS[${SEQC}]}"
			if [ "${BUFF:0:${STARTSEQL}}" == "${STARTSEQS[${SEQC}]}" ]; then
				FLIP="1"
				if [ "${EL}" ]; then
					echo -n "${EL}" | lowdown -tterm
					EL=
				fi
				break
			fi
			((SEQC++))
		done
		if [ "${FLIP}" == "0" ] && [ "${DELAY}" -eq "0" ]; then
			if [ "${BUFF:0:1}" == $'\n' ]; then
				[ "${EL}" ] && echo -n "${EL}" | lowdown -tterm
				EL=
			else
				EL="${EL}${BUFF:0:1}"
			fi
		fi
		[ "${DELAY}" -gt "0" ] && ((DELAY--))
	fi
}

while IFS= read -r -N 1 BYTESTR; do
	[ "${#BUFF}" -lt "${BUFFS}" ] && BUFF="${BUFF}${BYTESTR}" && continue
	calc
	BUFF="${BUFF:1}${BYTESTR}"
done
while [ "${BUFF}" ]; do
	calc
	BUFF="${BUFF:1}"
done
[ "${EL}" ] && echo -n "${EL}" | lowdown -tterm
