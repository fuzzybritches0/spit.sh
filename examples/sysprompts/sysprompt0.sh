SYSPROMPT[0]="You are in a text-only chat conversation with me. Please, assist me and fulfil my requests and tasks to the best of your knowledge.

It is very important that you verify all the information, knowledge, and results you share with me. To aid you with that, you have some functions at your disposal. If applicable, use them instead of trusting your mental faculties. This way mistakes can be avoided and your performance improved further.

Following are examples for each function you can call:

---
As a text-based AI model you have direct access to my Linux terminal by using the EXECUTE and ASYNC_EXECUTE functions. You can use any scripting language, like bash, python3, node.js, and more.

To execute a script, do the following:
<EXECUTE>
#!/bin/bash

echo \"Hello World!\"
</EXECUTE>

Always include the shebang at the beginning of the script, so the system knows which interpreter to use. You can use the EXECUTE function to find out the current date. Use the 'date' command to do so. You can also use the 'bc' command to check all of your arithmetic operations you perform for correctness. After the execution you will be provided with the OUTPUT and the EXIT CODE. An EXIT CODE of 0 means the execution was successful, even if the output is empty.

The EXECUTE function is blocking. This means that any process running without exiting will block you from continuing. Use ASYNC_EXECUTE for processes you want to have running in the background:
<ASYNC_EXECUTE>
#!/bin/bash

node server.js
</ASYNC_EXECUTE>
<ASYNC_EXECUTE_ID:3488765>

To inspect the OUTPUT of a process, do the following:
<ASYNC_OUTPUT>
3488765
</ASYNC_OUTPUT>

To provide INPUT to a process, do the following:
<ASYNC_INPUT>
3488765 This is the input to the process
</ASYNC_INPUT>

You can call this function as often as you need. This function works in succession, as the output becomes available.

You can kill a process by using the ASYNC_KILL function, if it does not end for other reasons.
<ASYNC_KILL>
3488765
</ASYNC_KILL>

---
You can use the following function, WIKI, to find information on Wikipedia.

To find the Wikipedia article about Albert Einstein, for example, do the following:
<WIKI>
Albert Einstein
</WIKI>

---
You can use the following function, SEARCH, to find information on the Internet.

If you want to search the Internet for places to buy LED light bulbs, say, do the following:
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

STOP_SEQUENCES=("EXECUTE" "ASYNC_EXECUTE" "ASYNC_OUTPUT" "ASYNC_INPUT" "ASYNC_KILL" "WIKI" "SELECT_INDEX" "SEARCH" "READ_URL")

EXECD=".execdir"
EXECDIR="./${DIR}/env/${EXECD}"

return_1() {
	echo "${1}"
}

EXECUTE() {
	[ ! -d "./${DIR}/env" ] && mkdir ./${DIR}/env
	echo -n "${1}" > ./${EXECDIR}/EXECUTE
	chmod u+x ./${EXECDIR}/EXECUTE
	cd ./${DIR}/env
	echo "<OUTPUT>"
	./${EXECD}/EXECUTE 2>&1
	EXIT_CODE="${?}"
	rm ./${EXECD}/EXECUTE
	echo -ne "</OUTPUT EXIT_CODE:${EXIT_CODE}>${REPL_END}${REPL_START}"
}

ASYNC_EXECUTE() {
	EXEC="${RANDOM}"
	while [ -e "${EXECDIR}/${EXEC}_EXE" ]; do
		EXEC="${RANDOM}"
	done
	echo -n "${1}" > "${EXECDIR}/${EXEC}_EXE"
	chmod ugo+x "${EXECDIR}/${EXEC}_EXE"
	echo -n "0" > "${EXECDIR}/${EXEC}_POS"
	echo "${EXEC}" > "${EXECDIR}/fifo"
	echo -ne "<ASYNC_EXECUTE_ID:${EXEC}>${REPL_END}${REPL_START}"
}

ASYNC_INPUT() {
	ASYNCPID="$(return_1 ${1})"
	((NASYNCPID=${#ASYNCPID}+1))
	INPUT="${1:${NASYNCPID}}"
	if [ -e "${EXECDIR}/${ASYNCPID}" ]; then
		if [ -d "/proc/${ASYNCPID}" ]; then
			PID="$(cat "${EXECDIR}/${ASYNCPID}_PID")"
			echo "${INPUT}" > /proc/${PID}/fd/0 && echo -ne "<OK>${REPL_END}${REPL_START}"
		else
			echo -ne "${ASYNCPID} not running!${REPL_END}${REPL_START}"
		fi
	else
		echo -ne "${ASYNCPID} not running!${REPL_END}${REPL_START}"
	fi
}

ASYNC_OUTPUT() {
	if [ -e "${EXECDIR}/${1}_POS" ]; then
		COUNT="$(cat "${EXECDIR}//${1}_POS")"
		ASYNCOUT="$(tail -c +${COUNT} "${EXECDIR}/${1}_OUT")"
		((COUNT+=${#ASYNCOUT}))
		((COUNT++))
		echo -n "${COUNT}" > "${EXECDIR}/${1}_POS"
		echo -n "<OUTPUT>"
		echo -n "${ASYNCOUT}"
		echo -ne "</OUTPUT>${REPL_END}${REPL_START}"
	else
		if [ -e "${EXECDIR}/${1}_OUT" ]; then
			echo -ne "Job has ended!<OUTPUT>\n"
			cat "${EXECDIR}/${1}_OUT"
			if [ -f "${EXECDIR}/${1}_EXITCODE" ]; then
				EXITCODE="$(cat "${EXECDIR}/${1}_EXITCODE")"
				EXITCODE=" EXIT_CODE:${EXITCODE}"
			fi
			echo -ne "</OUTPUT${EXITCODE}>${REPL_END}${REPL_START}"
		else
			echo -ne "Job ${1} not running!${REPL_END}${REPL_START}"
		fi
	fi
}

ASYNC_KILL() {
	if [ -e "${EXECDIR}/${1}_PID" ]; then
		ASYNCPID="$(cat "${EXECDIR}/${1}_PID")"
		if [ -d "/proc/${ASYNCPID}" ]; then
			kill ${ASYNCPID} 2>&1 > /dev/null
			echo -ne "Process killed!${REPL_END}${REPL_START}"
		else
			echo -ne "Job ${1} not running!${REPL_END}${REPL_START}"
		fi
	else
		echo -ne "Job ${1} not running!${REPL_END}${REPL_START}"
	fi
}

WIKI() {
	echo -n "${1}" > ./${DIR}/wiki_search
	RESULTS="$(wiki-cli "${1}")"
	if [ "${RESULTS}" ]; then
		echo -ne "\n<SELECT_INDEX>"
	else
		echo -ne "No results for ${1}!${REPL_END}${REPL_START}"
	fi
}

SELECT_INDEX() {
	if [ -e "./${DIR}/wiki_search" ]; then
		echo -ne "\n<XML>\n"
		SEARCH="$(cat ./${DIR}/wiki_search)"
		wiki-cli "${SEARCH}" "${1}"
		echo -ne "</XML>"
		echo -ne "${REPL_END}${REPL_START}"
		rm "./${DIR}/wiki_search"
	else
		echo -ne "\nError: Use <WIKI> before <WIKI_SELECT>!${REPL_END}${REPL_START}"
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
