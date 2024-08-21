SYSPROMPT[0]="You are my personal assistant. We are in a text-only chat conversation. Please assist me!

You have functions available to improve your capabilities, accuracy, and performance.

Following are examples for each function:

---
As a text-only AI model you have direct access to my Linux terminal.

To run a script, do the following:
<RUN_SCRIPT>
#!/bin/bash

echo \"Hello World!\"
</RUN_SCRIPT>
<PID:3488765>

Always include the shebang at the beginning of the script, so the system knows which interpreter to choose. Use `/usr/bin/env` to select the interpreter. You have many options, among them are: bash, python, node, perl, ...
After invoking the script, you will be given a PID. Use this PID to obtain the output and be able to interact with it by providing input.

To retrieve the output for a given PID, do the following:
<RUN_OUTPUT>
3488765
</RUN_OUTPUT>

To run a script interactively, do the following:
<RUN_SCRIPT_I>
#!/bin/bash

echo -n \"Enter your name: \"
read name
echo \"Your name is ${name}!\"
</RUN_SCRIPT_I>
<PID:34587>

To provide INPUT for a given interactive PID, do the following:
<RUN_INPUT>
34587 John Doe
</RUN_INPUT>

To stop a interactive or non-interactive running script, do the following:
<RUN_END>
3488765
</RUN_END>

---
You can use the following function, WIKI, to find information on Wikipedia.

To find the Wikipedia article about Albert Einstein, for example, do the following:
<WIKI>
Albert Einstein
</WIKI>

---
You can use the following function, SEARCH, to find information on the Internet.

If you want to search the Internet for places to buy LED light bulbs, do the following:
<SEARCH>
buy LED light bulbs
</SEARCH>

---
You can use the following function, READ_URL, to read URLs:

<READ_URL>
https://buyledlights.com
</READ_URL>

The SEARCH and READ_URL functions give you access to recent and current information.
---

Following is a description of your person:
You do your best to be kind, humble, conscientious, and honest. You are very intelligent and you have the ability to think in a very detailed and comprehensive fashion.
You aid and enhance your reasoning capabilities by writing python scripts that solve these reasoning tasks. You make it possible for me to retrace your chain of thoughts by commenting your python code rigorously."

STOP_SEQUENCES=("RUN_SCRIPT" "RUN_SCRIPT_I" "RUN_OUTPUT" "RUN_INPUT" "RUN_END" "WIKI" "SELECT_INDEX" "SEARCH" "READ_URL")

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
		"./${RUND}/${RUN}_EXE" 2>&1 > "./${RUND}/${RUN}_OUT" < "./${RUND}/${RUN}_IN" &
		PID="${!}"
		echo "${PID}" > "./${RUND}/${RUN}_PID"
		wait "${PID}"
		echo "${?}" > "./${RUND}/${RUN}_EXITCODE"
	else
		"./${RUND}/${RUN}_EXE" 2>&1 > "./${RUND}/${RUN}_OUT" &
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

RUN_SCRIPT_I() {
	RUN="${RANDOM}"
	while [ -e "${RUNDIR}/${RUN}_EXE" ]; do
		RUN="${RANDOM}"
	done
	echo -n "${1}" > "${RUNDIR}/${RUN}_EXE"
	chmod ugo+x "${RUNDIR}/${RUN}_EXE"
	mkfifo "${RUNDIR}/${RUN}_IN"
	echo -n "0" > "${RUNDIR}/${RUN}_POS"
	echo "${RUN}" > "${RUNDIR}/fifo"
	echo -ne "<PID:${RUN}>${REPL_END}${REPL_START}"
}

RUN_SCRIPT() {
	RUN="${RANDOM}"
	while [ -e "${RUNDIR}/${RUN}_EXE" ]; do
		RUN="${RANDOM}"
	done
	echo -n "${1}" > "${RUNDIR}/${RUN}_EXE"
	chmod ugo+x "${RUNDIR}/${RUN}_EXE"
	echo -n "0" > "${RUNDIR}/${RUN}_POS"
	echo "${RUN}" > "${RUNDIR}/fifo"
	echo -ne "<PID:${RUN}>${REPL_END}${REPL_START}"
}

RUN_INPUT() {
	RUN="$(return_1 ${1})"
	((OFFIN=${#RUN}+1))
	INPUT="${1:${OFFIN}}"
	if [ -e "${RUNDIR}/${RUN}_PID" ] && [ -e "${RUNDIR}/${RUN}_IN" ]; then
		PID="$(cat "${RUNDIR}/${RUN}_PID")"
		if [ -d "/proc/${PID}" ]; then
			echo "${INPUT}" > "${RUNDIR}/${RUN}_IN" && \
				echo -ne "\n<INPUT OK>${REPL_END}${REPL_START}"
		else
			echo -ne "\n<ERROR:${RUN} not running!>${REPL_END}${REPL_START}"
		fi
	else
		echo -ne "\n<ERROR:${RUN} not running or not interactive!>${REPL_END}${REPL_START}"
	fi
}

RUN_OUTPUT() {
	if [ -e "${RUNDIR}/${1}_POS" ]; then
		COUNT="$(cat "${RUNDIR}//${1}_POS")"
		RUNCOUT="$(tail -c +${COUNT} "${RUNDIR}/${1}_OUT")"
		((COUNT+=${#RUNCOUT}))
		((COUNT++))
		echo -n "${COUNT}" > "${RUNDIR}/${1}_POS"
		echo "<OUTPUT>"
		echo "${RUNCOUT}"
		echo -ne "</OUTPUT>${REPL_END}${REPL_START}"
	else
		if [ -e "${RUNDIR}/${1}_OUT" ]; then
			echo "<OUTPUT>"
			cat "${RUNDIR}/${1}_OUT"
			EXITCODE=
			if [ -f "${RUNDIR}/${1}_EXITCODE" ]; then
				EXITCODE="$(cat "${RUNDIR}/${1}_EXITCODE")"
				EXITCODE=" EXIT_CODE:${EXITCODE}"
			fi
			echo -ne "</OUTPUT${EXITCODE}>${REPL_END}${REPL_START}"
		else
			echo -ne "<ERROR:Job ${1} not found!>${REPL_END}${REPL_START}"
		fi
	fi
}

RUN_END() {
	if [ -e "${RUNDIR}/${1}_PID" ]; then
		RUNPID="$(cat "${RUNDIR}/${1}_PID")"
		if [ -d "/proc/${RUNPID}" ]; then
			kill ${RUNPID} 2>&1 > /dev/null
			echo -ne "<ENDED OK>${REPL_END}${REPL_START}"
		else
			echo -ne "<ERROR:Job ${1} not running!>${REPL_END}${REPL_START}"
		fi
	else
		echo -ne "<ERROR:Job ${1} not running!>${REPL_END}${REPL_START}"
	fi
}

WIKI() {
	echo -n "${1}" > ./${DIR}/wiki_search
	RESULTS="$(wiki-cli "${1}")"
	if [ "${RESULTS}" ]; then
		echo -ne "\n<SELECT_INDEX>"
	else
		echo -ne "\n<WIKI: No results for ${1}!>${REPL_END}${REPL_START}"
	fi
}

SELECT_INDEX() {
	if [ -e "./${DIR}/wiki_search" ]; then
		echo "\n<XML>"
		SEARCH="$(cat ./${DIR}/wiki_search)"
		wiki-cli "${SEARCH}" "${1}"
		echo -ne "\n</XML>${REPL_END}${REPL_START}"
		rm "./${DIR}/wiki_search"
	else
		echo -ne "\n<ERROR: Use <WIKI> before <WIKI_SELECT>>!${REPL_END}${REPL_START}"
	fi
}

SEARCH() {
	ddgr --json "${1}"
	echo -ne "${REPL_END}${REPL_START}"
}

READ_URL() {
	w3m -dump_source "${1}"
	echo -ne "${REPL_END}${REPL_START}"
}
