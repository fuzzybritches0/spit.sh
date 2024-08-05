#!/bin/bash
# SPDX-License-Identifier: GPL-2.0

return_1() {
	echo "${1}"
}

return_8() {
	echo "${8}"
}

return_9() {
	echo "${9}"
}

return_13() {
	echo "${13}"
}

options() {
	COUNT=1
	for OPTION in "${@}"; do
		((COUNT++))
		[ "${OPTION}" == "--id" ] && ID="${@:${COUNT}:1}" && LCOUNT="${COUNT}" && continue
		[ "${OPTION}" == "--sysid" ] && SID="${@:${COUNT}:1}" &&\
			LCOUNT="${COUNT}" && continue
	done
	((LCOUNT++))
	INPUT="${@:${LCOUNT}}"
}

help_screen() {
	echo
	echo "HELP"
	echo "----"
	echo "spit.sh v0.0.2"
	echo
	echo "${0} [ -h || --help ]"
	echo "${0} [ --id CHAT_SESSION_ID ] [ --sysid SYSTEM_ID ] [ INPUT ]"
	echo
	echo "CHAT_ID           an identifier for a new or existing chat session (mandatory)"
	echo "SYSTEM_ID         a numeric identifier for the system prompt (if omitted '0' is assumed)"
	echo "INPUT             INPUT non-interactively"
	echo "-h|--help         show this here help screen"
	echo
}

exit_fail() {
	echo "ERROR: ${1}"
	exit ${2}
}

exit_fail_log() {
	cat ./log_${SID}
	exit ${1}
}

read_input() {
	echo
	echo -n "$ "
	if [ "${TEST[${TCOUNT}]}" ]; then
		echo "${TEST[${TCOUNT}]}"
		INPUT="${TEST[${TCOUNT}]}"
		((TCOUNT++))
	else
		read INPUT
	fi
	echo
}

save_input() {
	echo -ne "${INST_START}" >> "${FPROMPT}"
	echo -ne "${INPUT}" >> "${FPROMPT}"
	echo -ne "${INST_END}" >> "${FPROMPT}"
	echo -ne "${REPL_START}" >> "${FPROMPT}"

}

init_prompt_chat() {
	COUNT=0
	while true; do
		[ ! "${CHAT[${COUNT}]}" ] && break
		echo -ne "${INST_START}"
		echo -ne "${CHAT[${COUNT}]}"
		((COUNT+=1))
		[ "${INST_START_NEXT}" ] && INST_START="${INST_START_NEXT}"
		echo -ne "${INST_END}"
		echo -ne "${REPL_START}"
		echo -ne "${CHAT[${COUNT}]}"
		echo -ne "${REPL_END}"
		((COUNT+=1))
	done
}

init_prompt() {
	if [ "${SYSTEM}" ]; then
		echo -ne "${SYS_START}" >> "${FPROMPT}"
		echo -ne "${SYSTEM}" >> "${FPROMPT}"
		echo -ne "${SYS_END}" >> "${FPROMPT}"
	fi
	init_prompt_chat >> "${FPROMPT}"
}

spit_predict() {
	PROG_P=(--prompt-cache "${FCACHE}"
		--prompt-cache-all
		--file "${FPROMPT}"
		--n_predict -2
		--simple-io
		"${REV_PROMPTS[@]}"
		--no-display-prompt)

	if [ "${DEBUG}" ]; then
		echo -n "RUNNING: ${PROG[@]} ${PROG_P[@]}"
		${PROG} "${PROG_P[@]}" 2> "${FLOG}" | tee -a "${FPROMPT}"
		[ "${PIPESTATUS[0]}" -ne "0" ] && exit_fail_log ${PIPESTATUS[0]}
	else
		${PROG} "${PROG_P[@]}" 2> "${FLOG}" | tee -a "${FPROMPT}"
		[ "${PIPESTATUS[0]}" -ne "0" ] && exit_fail_log ${PIPESTATUS[0]}
	fi

	PROMPT="$(cat "${FPROMPT}")"

	mv ./main.log "${DIR}"

}

spit_cache() {
	if [ "${BOS}" ]; then
		cp "${FPROMPT}" "${FPROMPT}_tmp"
		echo -ne "${BOS}" >> "${FPROMPT}"
	fi

	PROG_P=(--prompt-cache "${FCACHE}"
		--prompt-cache-all
		--file "${FPROMPT}"
		--n_predict 1
		--simple-io
		--no-display-prompt)

	if [ "${DEBUG}" ]; then
		echo -n "RUNNING: ${PROG[@]} ${PROG_P[@]}"
		${PROG} "${PROG_P[@]}" 2> "${FLOG}" || exit_fail_log ${?}
	else
		${PROG} "${PROG_P[@]}" 2> "${FLOG}" > /dev/null || exit_fail_log ${?}
	fi
	[ "${1}" ] && mv ./main.log ./${DIR}
	[ "${BOS}" ] && mv "${FPROMPT}_tmp" "${FPROMPT}"
}

process_stop_sequence() {
	SEQ="$(detect_stop_sequence)"
	if [ "${SEQ}" ]; then
		SEQ_START="<${SEQ}>"
		SEQ_STOP="</${SEQ}>"
		((STEPS=${#PROMPT}-${#SEQ_START}))
		for STEP in $(seq ${STEPS} -1 0); do
			((OFFSETL=STEP+${#SEQ_START}))
			((OFFSETR=${#PROMPT}-${OFFSETL}-${#SEQ_STOP}))
			if [ "${PROMPT:${STEP}:${#SEQ_START}}" == "${SEQ_START}" ]; then
				EXEC="${PROMPT:${OFFSETL}:${OFFSETR}}"
				break
			fi
		done
		((ENDP=${#EXEC}-1))
		while [ "${EXEC:${ENDP}:1}" == " " ] || [ "${EXEC:${ENDP}:1}" == $'\n' ]; do
			EXEC="${EXEC:0:${ENDP}}"
			((ENDP--))
		done
		while [ "${EXEC:0:1}" == " " ] || [ "${EXEC:0:1}" == $'\n' ]; do
			EXEC="${EXEC:1}"
		done
		"${SEQ}" "${EXEC}" | tee -a "${FPROMPT}"
		PROMPT="$(cat "${FPROMPT}")"
	fi
}

stop_on_sequences() {
	for EACH in ${STOP_SEQUENCES[@]}; do
		REV_PROMPTS=(${REV_PROMPTS[@]} --reverse-prompt "</${EACH}>")
	done
}

detect_stop_sequence() {
	for EACH in ${STOP_SEQUENCES[@]}; do
		_EACH="</${EACH}>"
		((OFFSETD=${#PROMPT}-${#_EACH}))
		if [ "${PROMPT:${OFFSETD}:${#_EACH}}" == "${_EACH}" ]; then
			echo "${EACH}"
			break
		fi
	done
}

stop_on_eos_token() {
	[ "${EOS}" ] && REV_PROMPTS=(${REV_PROMPTS[@]} --reverse-prompt ${EOS})
}

remove_eos_token() {
	if [ "${EOS}" ]; then
		((OFFSETR=${#PROMPT}-${#EOS}))
		if [ "${PROMPT:${OFFSETR}:${#EOS}}" == "${EOS}" ]; then
			PROMPT="${PROMPT:0:${OFFSETR}}"
			REMOVED_EOS_TOKEN=1
		fi
	fi
}

options "${@}"

[ "${1}" == "-h" ] || [ "${1}" == "--help" ] && \
	help_screen && exit 0

[ ! "${ID}" ] && help_screen && exit_fail "no ID given!" 1

[ ! -f "./spit.conf.sh" ] && exit_fail "./spit.conf.sh missing!" 1

[ ! "${SID}" ] && SID=0

. ./spit.conf.sh

SYSTEM="${SYSPROMPT[${SID}]}"

LLAMA="$(return_1 ${PROG})"
[ ! "${PROG}" ] && exit_fail "PROG not set!" 1
[ ! "$(which ${LLAMA})" ] && exit_fail "${LLAMA} not found!" 1

[ "${EOS}" ] && stop_on_eos_token
stop_on_sequences

INTERACTIVE=1
[ "${INPUT}" ] && INTERACTIVE=

FPROMPT="./prompt_${SID}"
FCACHE="./cache_${SID}"
FLOG="./log_${SID}"
if [ ! -f "${FCACHE}" ] && [ "${SYSTEM}${CHAT[0]}" ]; then
	[ "${INTERACTIVE}" ] && echo "caching..."
	init_prompt
	spit_cache
fi
[ ! "${SYSTEM}" ] && touch "${FPROMPT}"

OFPROMPT="${FPROMPT}"
OFCACHE="${FCACHE}"
OFLOG="${FLOG}"

DIR="${ID}_${SID}"
FPROMPT="./${DIR}/prompt"
FCACHE="./${DIR}/cache"
FLOG="./${DIR}/log"
FINPUT="./${DIR}/input"

[ ! -d "./${DIR}" ] && mkdir "${DIR}"
[ ! -f "${FPROMPT}" ] && [ -f "${OFPROMPT}" ] && cp "${OFPROMPT}" "${FPROMPT}"
[ ! -f "${FCACHE}" ] && [ -f "${OFCACHE}" ] && cp "${OFCACHE}" "${FCACHE}"
[ ! -f "${FLOG}" ] && [ -f "${OFLOG}" ] && cp "${OFLOG}" "${FLOG}"

TCOUNT=0

cat "${FPROMPT}"

while true; do
	if [ "${INTERACTIVE}" ]; then
		read_input
	elif [ -f "${FINPUT}" ]; then
		INPUT="$(cat "${FINPUT}")"
	fi

	[ ! "${INPUT}" ] && exit 0

	if [ "${INTERACTIVE}" ] && [ "${INPUT}" == "<file" ]; then
		if [ ! -f "${FINPUT}" ]; then
			echo "ERROR: ${FINPUT} not found!"
		else
			INPUT="$(cat "${FINPUT}")"
		fi
	fi
	save_input
	INPUT=

	while true; do
		cp "${FPROMPT}" "${FPROMPT}_last"
		spit_predict
		remove_eos_token
		echo "${PROMPT}" > "${FPROMPT}"
		rm -f "${FINPUT}"

		if [ "${REMOVED_EOS_TOKEN}" ]; then
			REMOVED_EOS_TOKEN=
			break
		fi
		if [ "$(detect_stop_sequence)" ]; then
			process_stop_sequence
		else
			break
		fi
	done

	echo

	echo -ne "${REPL_END}" >> "${FPROMPT}"

	[ ! "${INTERACTIVE}" ] && break

	[ "${INST_START_NEXT}" ] && INST_START="${INST_START_NEXT}" && INST_START_NEXT=
done
