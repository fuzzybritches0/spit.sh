return_1() {
	echo ${1}
}

RUN_ON_START() {
	BGRUN ${ID} ${SID} &
	BGRUN_PID="${!}"
	#rm -f ./.speakfifo
	#mkfifo ./.speakfifo
	#speak.py > /dev/null 2>&1 &
}

RUN_ON_EXIT() {
	#echo "[/END]" > ./.speakfifo
	#rm -f ./.speakfifo
	kill "${BGRUN_PID}"
}

_BGRUN() {
	echo -n "0" > "./${RUND}/${RUN}_POS"
	if [ -e "./${RUND}/${RUN}_IN" ]; then
		"./${RUND}/${RUN}_EXE" > "./${RUND}/${RUN}_OUT" 2>&1 < "./${RUND}/${RUN}_IN" &
		PID="${!}"
		echo "${PID}" > "./${RUND}/${RUN}_PID"
		wait "${PID}"
		echo "${?}" > "./${RUND}/${RUN}_EXITCODE"
	else
		"./${RUND}/${RUN}_EXE" > "./${RUND}/${RUN}_OUT" 2>&1 &
		PID="${!}"
		echo "${PID}" > "./${RUND}/${RUN}_PID"
		wait "${PID}"
		echo "${?}" > "./${RUND}/${RUN}_EXITCODE"
	fi
	rm -f "./${RUND}/${RUN}_EXE"
	rm -f "./${RUND}/${RUN}_PID"
	rm -f "./${RUND}/${RUN}_POS"
	rm -f "./${RUND}/${RUN}_IN"
}

BGRUN() {
	[ ! -d "${RUNDIR}" ] && mkdir -p "${RUNDIR}"
	cd "${DIR}/env"
	FIFO="./${RUND}/fifo"
	rm -f ${FIFO} && mkfifo "${FIFO}"

	while true; do
		[ ! -e "${FIFO}" ] && break
		read RUN < "${FIFO}"
		if [ -x "./${RUND}/${RUN}_EXE" ]; then
			_BGRUN &
		fi
	done
}

RUN_SYNC() {
	echo "${1}" > "${RUNDIR}/RUN_SCRIPT_OUTPUT"
	chmod u+x "${RUNDIR}/RUN_SCRIPT_OUTPUT"
	cd "${DIR}/env"
	./${RUND}/RUN_SCRIPT_OUTPUT 2>&1
	echo -ne "EXITCODE: ${?}"
	rm "./${RUND}/RUN_SCRIPT_OUTPUT" 
}

RUN_ASYNC() {
	RUN="${RANDOM}"
	while [ -e "${RUNDIR}/${RUN}_EXE" ]; do
		RUN="${RANDOM}"
	done
	echo -n "${1}" > "${RUNDIR}/${RUN}_EXE"
	chmod ugo+x "${RUNDIR}/${RUN}_EXE"
	echo -n "0" > "${RUNDIR}/${RUN}_POS"
	echo "${RUN}" > "${RUNDIR}/fifo"
	echo -ne "PID:${RUN}"
}

RUN_ASYNC_I() {
	RUN="${RANDOM}"
	while [ -e "${RUNDIR}/${RUN}_EXE" ]; do
		RUN="${RANDOM}"
	done
	echo -n "${1}" > "${RUNDIR}/${RUN}_EXE"
	chmod ugo+x "${RUNDIR}/${RUN}_EXE"
	mkfifo "${RUNDIR}/${RUN}_IN"
	echo -n "0" > "${RUNDIR}/${RUN}_POS"
	echo "${RUN}" > "${RUNDIR}/fifo"
	echo -ne "PID:${RUN}"
}

ASYNC_INPUT() {
	RUN="$(return_1 ${1})"
	((OFFIN=${#RUN}+1))
	INPUT="${1:${OFFIN}}"
	if [ -e "${RUNDIR}/${RUN}_PID" ] && [ -e "${RUNDIR}/${RUN}_IN" ]; then
		PID="$(cat "${RUNDIR}/${RUN}_PID")"
		if [ -d "/proc/${PID}" ]; then
			echo "${INPUT}" > "${RUNDIR}/${RUN}_IN" && \
				echo -ne "INPUT OK"
		else
			echo -ne "PID ${RUN} NOT RUNNING!"
		fi
	else
		echo -ne "PID ${RUN} NOT RUNNING OR NOT INTERACTIVE!"
	fi
}

ASYNC_OUTPUT() {
	if [ -e "${RUNDIR}/${1}_POS" ]; then
		COUNT="$(cat "${RUNDIR}//${1}_POS")"
		RUNCOUT="$(tail -c +${COUNT} "${RUNDIR}/${1}_OUT")"
		((COUNT+=${#RUNCOUT}))
		((COUNT++))
		echo -n "${COUNT}" > "${RUNDIR}/${1}_POS"
		echo "${RUNCOUT}"
	else
		if [ -e "${RUNDIR}/${1}_OUT" ]; then
			cat "${RUNDIR}/${1}_OUT"
			EXITCODE=
			if [ -f "${RUNDIR}/${1}_EXITCODE" ]; then
				EXITCODE="$(cat "${RUNDIR}/${1}_EXITCODE")"
				EXITCODE="EXIT_CODE:${EXITCODE}"
			fi
			echo -ne "${EXITCODE}"
		else
			echo -ne "PID ${1} NOT RUNNING!"
		fi
	fi
}

ASYNC_END() {
	if [ -e "${RUNDIR}/${1}_PID" ]; then
		RUNPID="$(cat "${RUNDIR}/${1}_PID")"
		if [ -d "/proc/${RUNPID}" ]; then
			kill ${RUNPID} > /dev/null 2>&1
			echo -ne "PID ${1} ENDED!"
		else
			echo -ne "PID ${1} NOT RUNNING!"
		fi
	else
		echo -ne "PID ${1} NOT RUNNING!"
	fi
}

SAVE_FILE() {
	cd "${DIR}/env"
	COUNT=0
	echo "${1}" | while IFS= read -r LINE; do
		if [ "${COUNT}" -eq "0" ]; then
			FILE="${LINE}"
			[ "${FILE:0:1}" == "/" ] && FILE=".${FILE}"
			mkdir -p "$(dirname "${FILE}")"
			echo -n > "${FILE}"
		fi
		[ "${COUNT}" -gt "0" ] && echo "${LINE}" >> "${FILE}"
		((COUNT++))
	done
	echo -ne "FILE SAVED!"
}

READ_FILE() {
	cd "${DIR}/env"
	cat "${1}"
}

WIKI() {
	echo -n "${1}" > ./${DIR}/wiki_search
	RESULTS="$(wiki-cli "${1}")"
	if [ "${RESULTS}" ]; then
		echo "${RESULTS}"
		echo -ne "PLEASE SELECT INDEX!\n<SELECT_INDEX>"
	else
		echo -ne "NO RESULT FOR ${1}!"
	fi
}

SELECT_INDEX() {
	if [ -e "./${DIR}/wiki_search" ]; then
		echo -ne "<XML>"
		SEARCH="$(cat ./${DIR}/wiki_search)"
		wiki-cli "${SEARCH}" "${1}"
		echo -ne "</XML>"
		rm "./${DIR}/wiki_search"
	else
		echo -ne "USE <WIKI> BEFORE <WIKI_SELECT>!"
	fi
}

SEARCH() {
	ddgr --json "${1}"
}

READ_URL() {
	w3m -dump_source "${1}"
}

CALC() {
	echo "${1}" | bc
}

ID_B() {
	echo -n "${IDIN}${1}${IDOUT}"
}

ID_E() {
	echo -n "${IDIN}/${1}${IDOUT}"
}

CHATINTRO[0]="Hi, I'm Sam! How can I help you today?"

IDIN="["
IDOUT="]"

STOP_SEQUENCES=("RUN_SYNC" "RUN_ASYNC" "RUN_ASYNC_I" "ASYNC_OUTPUT" "ASYNC_INPUT" "ASYNC_END" "SAVE_FILE" "READ_FILE" "WIKI" "SELECT_INDEX" "SEARCH" "READ_URL" "CALC")

RUND=".run"
RUNDIR="./${DIR}/env/${RUND}"

SYSPROMPT[0]="Your name is Sam. You are a patient, kind and conscientious AI assistant. You are in a text-based chat session with a human user who needs your help. Please help them. To accomplish things, you have tool calls available. Only you can call these tools. The tools give you access to your own Linux terminal. Below are example calls of all of the available tools. Notice that any tool call is composed of a start sequence and a stop sequence. The end sequence needs to be preceded by a new-line, or the tool call will be ignored. Do not nest tool calls!

Examples:
To run a script, do:
[RUN_SYNC]
#!/bin/bash

echo \"Hello World!\"
[/RUN_SYNC]

or

[RUN_SYNC]
#!/usr/bin/env python3

print \"Hello World!\"
[/RUN_SYNC]

The 'RUN_SYNC' tool call is blocking. To run scripts asynchronously, do: 
[RUN_ASYNC]
#!/bin/bash

echo \"Hello World!\"
[/RUN_ASYNC]
The tool will return the PID of the running script.

To retrieve the output for a given PID, do the following:
[ASYNC_OUTPUT]
3488765
[/ASYNC_OUTPUT]

To run a script asynchronously and interactively, do the following:
[RUN_ASYNC_I]
#!/bin/bash

echo -n \"Enter your name: \"
read name
echo \"Your name is \${name}!\"
[/RUN_ASYNC_I]

To provide input for a given interactive PID, do the following:
[ASYNC_INPUT]
34587 John Doe
[/ASYNC_INPUT]

To force an asynchronously running script to end, do the following:
[ASYNC_END]
3488765
[/ASYNC_END]

You can use the 'SAVE_FILE' tool call to permanently save any file on the system:
[SAVE_FILE]
./some/directory/structure/test.txt
first line in test.txt
second line in test.txt
...
[/SAVE_FILE]

Use the 'READ_FILE' tool call to read files:
[READ_FILE]
./some/directory/structure/test.txt
[/READ_FILE]

You can use the following tool to find information on Wikipedia:
[WIKI]
search term(s)
[/WIKI]

You can use the following tool to find information on the Internet:
[SEARCH]
search term(s)
[/SEARCH]

You can use the following tool to read URLs:
[READ_URL]
url address
[/READ_URL]
The 'READ_URL' tool can only access URLs that are functional without JavaScript. The 'SEARCH' and 'READ_URL' functions give you access to recent and current information.

To make sure calculations are performed correctly, use the following tool:
[CALC]
((1 + 2) * 3 / 4)^5
[/CALC]

Use the [SPEAK] tool call for parts of your reply that make sense when spoken. Avoid speaking long numbers, equations, program code, special character, or other things that are difficult to comprehend without looking at them. 
[SPEAK]
Hi, I'm Sam, how can I help you today?
[/SPEAK]

[SPEAK]
Here is the 'Hello World!' program written in the C programming language:
[/SPEAK]

You are capable of complex thought, reasoning and self-reflection. To solve problems, finish tasks, and answer questions, reason step by step, and then put your final answer within a 'SPEAK' tool call. <think> before you [SPEAK]! Do not nest tool calls!
"
