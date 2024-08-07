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

STOP_SEQUENCES=("EXECUTE" "ASYNC_EXECUTE" "ASYNC_OUTPUT" "ASYNC_KILL" "WIKI" "SELECT_INDEX" "SEARCH" "READ_URL")

[ -d "./${DIR}/env/.async_execute" ] && rm -rf ./${DIR}/env/.async_execute

EXECUTE() {
	[ ! -d "./${DIR}/env" ] && mkdir ./${DIR}/env
	echo "${1}" > ./${DIR}/EXECUTE
	chmod u+x ./${DIR}/EXECUTE
	cd ./${DIR}/env
	echo "<OUTPUT>"
	../EXECUTE 2>&1
	EXIT_CODE="${?}"
	rm ../EXECUTE
	echo -ne "</OUTPUT EXIT_CODE:${EXIT_CODE}>${REPL_END}${REPL_START}"
}

_ASYNC_WAIT() {
	wait ${1}
	rm -f ./${DIR}/env/.async_execute/${1}
	rm -f ./${DIR}/env/.async_execute/${1}_PID
	rm -f ./${DIR}/env/.async_execute/${1}_POS
}

ASYNC_EXECUTE() {
	[ ! -d "./${DIR}/env/.async_execute" ] && mkdir -p ./${DIR}/env/.async_execute
	EXEC="${RANDOM}"
	while [ -f "./${DIR}/env/.async_execute/${EXEC}" ]; do
		EXEC="${RANDOM}"
	done
	echo "${1}" > ./${DIR}/${EXEC}
	chmod u+x ./${DIR}/${EXEC}
	cd ./${DIR}/env
	../${EXEC} 2>&1 > ./${DIR}/env/.async_execute/${EXEC} &
	ASYNCPID="${1}"
	echo -n "${ASYNCPID}" > ./${DIR}/env/.async_execute/${EXEC}_PID
	echo -n "0" > ./${DIR}/env/.async_execute/${EXEC}_POS
	_ASYNC_WAIT ${ASYNCPID} &
	echo "<ASYNC_EXECUTE_ID:${EXEC}>${REPL_END}${REPL_START}"
}

ASYNC_OUTPUT() {
	if [ -f "./${DIR}/env/.async_execute/${1}_POS" ] && \
		[ -f "./${DIR}/env/.async_execute/${1}" ]; then
		COUNT="$(cat ./${DIR}/env/.async_execute/${1}_OUTPOS)"
		ASYNCOUT="$(tail -c +${COUNT} ./${DIR}/env/.async_execute/${1})"
		((COUNT+=${#ASYNCOUT}))
		echo -n "${COUNT}" > ./${DIR}/env/.async_execute/${1}_POS
		echo "<OUTPUT>"
		echo -n "${ASYNCOUT}"
		echo "</OUTPUT>"
	else
		echo "Job ${1} not found!"
	fi
}

ASYNC_KILL() {
	if [ -f "./${DIR}/env/.async_execute/${1}" ]; then
		EXECPID="$(cat ./${DIR}/env/.async_execute/${1})"
		kill ${EXECPID} 2>&1 > /dev/null && echo "ID ${1} killed!"
		rm -f ./${DIR}/env/.async_execute/${1}
		rm -f ./${DIR}/env/.async_execute/${1}_PID
		rm -f ./${DIR}/env/.async_execute/${1}_POS
	else
		echo "Job ${1} not found!"
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
	if [ -f "./${DIR}/wiki_search" ]; then
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
