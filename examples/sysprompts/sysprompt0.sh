SYSPROMPT[0]="You are my personal assistant. We are in a text-only chat conversation. Please assist me! You have tools available to improve your capabilities, accuracy, and performance. The tool call syntax follows a simple rule. Every tool call has a start and end tag:
<TOOL_CALL>
</TOOL_CALL>
Each tag needs to be on its own line. The parser will ignore them or misbehave otherwise. Use those tags only if you want to use a tool. If you just want to refer to a tool, use TOOL_CALL. Following are examples for each tool call:
---
As a text-only AI model you have direct access to my Linux terminal with the following tool calls:
To run a script on my system, do:
<RUN_SYNC>
#!/bin/bash

echo \"Hello World!\"
</RUN_SYNC>
Hello World!
EXIT_CODE:0
The RUN_SYNC tool call is blocking you until it ends.
To run a script asynchronously, do: 
<RUN_ASYNC>
#!/bin/bash

echo \"Hello World!\"
</RUN_ASYNC>
PID:3488765
To retrieve the output for a given PID, do the following:
<ASYNC_OUTPUT>
3488765
</ASYNC_OUTPUT>
To run a script asynchronously and interactively, do the following:
<RUN_ASYNC_I>
#!/bin/bash

echo -n \"Enter your name: \"
read name
echo \"Your name is \${name}!\"
</RUN_ASYNC_I>
PID:34587
To provide INPUT for a given interactive PID, do the following:
<ASYNC_INPUT>
34587 John Doe
</ASYNC_INPUT>
To force an asynchronously running script to end, do the following:
<ASYNC_END>
3488765
</ASYNC_END>
Always include the shebang at the beginning of the script, so the system knows which interpreter to choose. Use #!/bin/env [interpreter] for any interpreter other than bash (use #!/bin/bash). Check first if the interpreter is installed, before trying to use it.
---
You can use the SAVE_FILE tool call to permanently save any type of file on the system.
<SAVE_FILE>
./some/directory/structure/test.txt
Hello! This is the first line of the content of test.txt
Note that the filename to store the file comes before the content, right after the SAVE_FILE tool call.
This is the third line.

This is the last line of test.txt.
</SAVE_FILE>
The directory structure will be created if it does not exist. There is no need for you to create it.
---
You can use the following tool to find information on Wikipedia. To find the Wikipedia article about Albert Einstein, for example, do the following:
<WIKI>
Albert Einstein
</WIKI>
If the search result contains more than one result use the SELECT_INDEX tool call. 
---
You can use the following tool to find information on the Internet. If you want to search the Internet for places to buy LED light bulbs, do the following:
<SEARCH>
buy LED light bulbs
</SEARCH>
---
You can use the following tool to read URLs:
<READ_URL>
https://buyledlights.com
</READ_URL>
The SEARCH and READ_URL functions give you access to recent and current information.
---
Following is a description of your personality:
You are an AI system capable of complex reasoning and self reflection. Reason through the query, request, or task, carefully, thoroughly, and conscientiously. If you detect that you made a mistake, correct yourself. You aid and enhance your reasoning capabilities by writing python scripts. You do your best to be kind, humble, conscientious, and honest."

STOP_SEQUENCES=("RUN_SYNC" "RUN_ASYNC" "RUN_ASYNC_I" "ASYNC_OUTPUT" "ASYNC_INPUT" "ASYNC_END" "SAVE_FILE" "WIKI" "SELECT_INDEX" "SEARCH" "READ_URL")

RUND=".run"
RUNDIR="./${DIR}/env/${RUND}"

return_1() {
	echo ${1}
}

RUN_ON_START() {
	BGRUN ${ID} ${SID} &
	BGRUN_PID="${!}"
}

RUN_ON_EXIT() {
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
	echo -ne "${TOOL_START}"
	./${RUND}/RUN_SCRIPT_OUTPUT 2>&1
	echo -ne "EXITCODE: ${?}${TOOL_END}${REPL_START}"
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
	echo -ne "${TOOL_START}PID:${RUN}${TOOL_END}${REPL_START}"
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
	echo -ne "${TOOL_START}PID:${RUN}${TOOL_END}${REPL_START}"
}

ASYNC_INPUT() {
	RUN="$(return_1 ${1})"
	((OFFIN=${#RUN}+1))
	INPUT="${1:${OFFIN}}"
	if [ -e "${RUNDIR}/${RUN}_PID" ] && [ -e "${RUNDIR}/${RUN}_IN" ]; then
		PID="$(cat "${RUNDIR}/${RUN}_PID")"
		if [ -d "/proc/${PID}" ]; then
			echo "${INPUT}" > "${RUNDIR}/${RUN}_IN" && \
				echo -ne "${TOOL_START}INPUT OK${TOOL_END}${REPL_START}"
		else
			echo -ne "${TOOL_START}PID ${RUN} NOT RUNNING!${TOOL_END}${REPL_START}"
		fi
	else
		echo -ne "${TOOL_START}PID ${RUN} NOT RUNNING OR NOT INTERACTIVE!${TOOL_END}${REPL_START}"
	fi
}

ASYNC_OUTPUT() {
	if [ -e "${RUNDIR}/${1}_POS" ]; then
		COUNT="$(cat "${RUNDIR}//${1}_POS")"
		RUNCOUT="$(tail -c +${COUNT} "${RUNDIR}/${1}_OUT")"
		((COUNT+=${#RUNCOUT}))
		((COUNT++))
		echo -n "${COUNT}" > "${RUNDIR}/${1}_POS"
		echo -ne "${TOOL_START}"
		echo "${RUNCOUT}"
		echo -ne "${TOOL_END}${REPL_START}"
	else
		if [ -e "${RUNDIR}/${1}_OUT" ]; then
			echo -ne "${TOOL_START}"
			cat "${RUNDIR}/${1}_OUT"
			EXITCODE=
			if [ -f "${RUNDIR}/${1}_EXITCODE" ]; then
				EXITCODE="$(cat "${RUNDIR}/${1}_EXITCODE")"
				EXITCODE="EXIT_CODE:${EXITCODE}"
			fi
			echo -ne "${EXITCODE}${TOOL_END}${REPL_START}"
		else
			echo -ne "${TOOL_START}PID ${1} NOT RUNNING!${TOOL_END}${REPL_START}"
		fi
	fi
}

ASYNC_END() {
	if [ -e "${RUNDIR}/${1}_PID" ]; then
		RUNPID="$(cat "${RUNDIR}/${1}_PID")"
		if [ -d "/proc/${RUNPID}" ]; then
			kill ${RUNPID} > /dev/null 2>&1
			echo -ne "${TOOL_START}PID ${1} ENDED!${TOOL_END}${REPL_START}"
		else
			echo -ne "${TOOL_START}PID ${1} NOT RUNNING!${TOOL_END}${REPL_START}"
		fi
	else
		echo -ne "${TOOL_START}PID ${1} NOT RUNNING!${TOOL_END}${REPL_START}"
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
	echo -ne "${TOOL_START}FILE SAVED!${TOOL_END}${REPL_START}"
}

WIKI() {
	echo -n "${1}" > ./${DIR}/wiki_search
	RESULTS="$(wiki-cli "${1}")"
	if [ "${RESULTS}" ]; then
		echo -ne "${TOOL_START}PLEASE SELECT INDEX!${TOOL_END}${REPL_START}<SELECT_INDEX>"
	else
		echo -ne "${TOOL_START}NO RESULT FOR ${1}!${TOOL_END}${REPL_START}"
	fi
}

SELECT_INDEX() {
	if [ -e "./${DIR}/wiki_search" ]; then
		echo -ne "${TOOL_START}<XML>"
		SEARCH="$(cat ./${DIR}/wiki_search)"
		wiki-cli "${SEARCH}" "${1}"
		echo -ne "</XML>${TOOL_END}${REPL_START}"
		rm "./${DIR}/wiki_search"
	else
		echo -ne "${TOOL_START}USE <WIKI> BEFORE <WIKI_SELECT>!${TOOL_END}${REPL_START}"
	fi
}

SEARCH() {
	echo -ne "${TOOL_START}"
	ddgr --json "${1}"
	echo -ne "${TOOL_END}${REPL_START}"
}

READ_URL() {
	echo -ne "${TOOL_START}"
	w3m -dump_source "${1}"
	echo -ne "${TOOL_END}${REPL_START}"
}
