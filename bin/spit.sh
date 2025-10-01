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
		[ "${OPTION}" == "--continue" ] && CONTINUE=1 && LCOUNT="${COUNT}" && continue
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
	echo "${0} [ --id CHAT_SESSION_ID ] [ --sysid SYSTEM_ID ] [--continue] [ INPUT ]"
	echo
	echo "CHAT_ID           an identifier for a new or existing chat session (mandatory)"
	echo "SYSTEM_ID         a numeric identifier for the system prompt (if omitted '0' is assumed)"
	echo "INPUT             INPUT non-interactively"
	echo "-h|--help         show this here help screen"
	echo "--continue	continue generation/don't ask for input"
	echo
}

exit_fail() {
	echo "ERROR: ${1}"
	exit ${2}
}

exit_fail_log() {
	if [ -f "./log_${SID}" ]; then
		cat ./log_${SID}
	elif [ -f "../log" ]; then
		cat ../log
	fi
	exit ${1}
}

interactive_display() {
	if [ "${INTERACTIVE}" ]; then
		clear
		if [ "${CHATINTRO[${SID}]}" ]; then
			echo "# ASSISTANT:" | lowdown -tterm
			echo "${CHATINTRO[${SID}]}" | lowdown -tterm
			cat "${FCHAT}" | render.sh
		fi
	fi
}

read_input() {
	[ "${INTERACTIVE}" ] && echo
	if [ "${TEST[${TCOUNT}]}" ]; then
		echo -n "${TEST[${TCOUNT}]}"
		INPUT="${TEST[${TCOUNT}]}"
		((TCOUNT++))
	elif [ "$(which rlwrap)" ]; then
		INPUT="$(rlwrap -pGREEN -S "$ " -o cat)"
	else
		echo -ne "$ "
		read INPUT
	fi
}

save_input() {
	echo -ne "${INST_START}" >> "${FPROMPT}"
	echo -ne "${INPUT}" >> "${FPROMPT}"
	echo -ne "${INST_END}" >> "${FPROMPT}"
	echo -ne "${REPL_START}" >> "${FPROMPT}"
	echo -ne "# USER:\n${INPUT}\n" >> "${FCHAT}"

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
		--cache_prompt true
		--file "${FPROMPT}"
		--n_predict -1
		"${REV_PROMPTS[@]}")
	if [ "${PREFIX}" ]; then
		if [ "$(tail -c ${#PREFIX} "${FCHAT}")" != "${PREFIX}" ]; then
			echo -ne "${PREFIX}" >> "${FCHAT}"
		fi
	fi
	if [ "${DEBUG}" ]; then
		${PROG} "${PROG_P[@]}" 2> "${FLOG}" | tee -a "${FPROMPT}" "${FCHAT}"
		[ "${PIPESTATUS[0]}" -ne "0" ] && exit_fail_log ${PIPESTATUS[0]}
	else
		${PROG} "${PROG_P[@]}" 2> "${FLOG}" | tee -a "${FPROMPT}" "${FCHAT}" |\
			render.sh SPEAK
		[ "${PIPESTATUS[0]}" -ne "0" ] && exit_fail_log ${PIPESTATUS[0]}
	fi

	PROMPT="$(cat "${FPROMPT}")"
	[ "$(tail -c 1 "${FCHAT}")" != $'\n' ] && echo >> "${FCHAT}"
}

_process_stop_sequence() {
	echo -ne '\n```\n' | tee -a "${FCHAT}"
	echo -ne '\n```'  | tee -a "${FCHAT}"
}

process_stop_sequence() {
	SEQ="$(detect_stop_sequence)"
	if [ "${SEQ}" ]; then
		SEQ_START="$(ID_B ${SEQ})"
		SEQ_STOP="$(ID_E ${SEQ})"
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
		echo -ne "${TOOL_START}" | tee -a "${FPROMPT}" >> "${FCHAT}"
		"${SEQ}" "${EXEC}" | tee -a "${FPROMPT}" "${FCHAT}"
		echo -ne "${TOOL_END}" | tee -a  "${FPROMPT}" >> "${FCHAT}"
		PROMPT="$(cat "${FPROMPT}")"
	fi
}

stop_on_sequences() {
	for EACH in ${STOP_SEQUENCES[@]}; do
		REV_PROMPTS=(${REV_PROMPTS[@]} --stop "$(ID_E ${EACH})")
	done
}

detect_stop_sequence() {
	for EACH in ${STOP_SEQUENCES[@]}; do
		_EACH="$(ID_E ${EACH})"
		((OFFSETD=${#PROMPT}-${#_EACH}))
		if [ "${PROMPT:${OFFSETD}:${#_EACH}}" == "${_EACH}" ]; then
			echo "${EACH}"
			break
		fi
	done
}

stop_on_eot_token() {
	[ "${EOT}" ] && REV_PROMPTS=(${REV_PROMPTS[@]} --stop "${EOT}")
}

remove_eot_token() {
	if [ "${EOT}" ]; then
		((OFFSETR=${#PROMPT}-${#EOT}))
		if [ "${PROMPT:${OFFSETR}:${#EOT}}" == "${EOT}" ]; then
			PROMPT="${PROMPT:0:${OFFSETR}}"
			return 0
		fi
	fi
	return 1
}

options "${@}"

[ "${1}" == "-h" ] || [ "${1}" == "--help" ] && \
	help_screen && exit 0

[ ! "${ID}" ] && help_screen && exit_fail "no ID given!" 1

[ ! -e "./spit.conf.sh" ] && exit_fail "./spit.conf.sh missing!" 1

[ ! "${SID}" ] && SID=0

DIR="${ID}_${SID}"
. ./spit.conf.sh

[ "$(type RUN_ON_START 2> /dev/null | grep "is a function")" ] && RUN_ON_START

SYSTEM="${SYSPROMPT[${SID}]}"

LLAMA="$(return_1 ${PROG})"
[ ! "${PROG}" ] && exit_fail "PROG not set!" 1
[ ! "$(which ${LLAMA})" ] && exit_fail "${LLAMA} not found!" 1

[ "${EOT}" ] && stop_on_eot_token
stop_on_sequences

INTERACTIVE=1
[ "${INPUT}" ] && INTERACTIVE=

FPROMPT="./prompt_${SID}"
#FCACHE="./cache_${SID}"
FLOG="./log_${SID}"
if [ ! -e "${FPROMPT}" ] && [ "${SYSTEM}${CHAT[0]}" ]; then
	init_prompt
fi
[ ! "${SYSTEM}" ] && touch "${FPROMPT}"

OFPROMPT="${FPROMPT}"
#OFCACHE="${FCACHE}"
OFLOG="${FLOG}"

FCHAT="./${DIR}/chat"
FPROMPT="./${DIR}/prompt"
#FCACHE="./${DIR}/cache"
FLOG="./${DIR}/log"
FINPUT="./${DIR}/input"

[ ! -d "./${DIR}" ] && mkdir "${DIR}"
[ ! -e "${FPROMPT}" ] && [ -e "${OFPROMPT}" ] && cp "${OFPROMPT}" "${FPROMPT}"
#[ ! -e "${FCACHE}" ] && [ -e "${OFCACHE}" ] && cp "${OFCACHE}" "${FCACHE}"
[ ! -e "${FLOG}" ] && [ -e "${OFLOG}" ] && cp "${OFLOG}" "${FLOG}"
[ ! -e "${FCHAT}" ] && touch "${FCHAT}"

TCOUNT=0
interactive_display

while true; do
	if [ ! "${CONTINUE}" ]; then
		if [ "${INTERACTIVE}" ]; then
			read_input
		elif [ -e "${FINPUT}" ]; then
			INPUT="$(cat "${FINPUT}")"
		fi
	
		if [ ! "${INPUT}" ]; then
			[ "$(type RUN_ON_EXIT 2> /dev/null | grep "is a function")" ] && RUN_ON_EXIT
			exit 0
		fi
	
		if [ "${INTERACTIVE}" ] && [ "${INPUT}" == "<file" ]; then
			if [ ! -e "${FINPUT}" ]; then
				echo "ERROR: ${FINPUT} not found!"
			else
				INPUT="$(cat "${FINPUT}")"
			fi
		fi
		save_input
		interactive_display
		INPUT=
	fi
	CONTINUE=

	[ "$(tail -c 16 "${FCHAT}")" != "# ASSISTANT:" ] && \
		echo -ne "\n# ASSISTANT: " >> "${FCHAT}"
	[ "${INTERACTIVE}" ] && echo -n "# ASSISTANT: " | lowdown -tterm
	while true; do
		cp "${FPROMPT}" "${FPROMPT}_last"
		spit_predict
		rm -f "${FINPUT}"

		if remove_eot_token; then
			echo -ne "${PROMPT}" > "${FPROMPT}"
			break
		fi
		if [ "$(detect_stop_sequence)" ]; then
			process_stop_sequence
		else
			break
		fi
	done
	echo >> "${FCHAT}"
	echo -ne "${REPL_END}" >> "${FPROMPT}"
	interactive_display

	if [ ! "${INTERACTIVE}" ]; then
		[ "$(type RUN_ON_EXIT 2> /dev/null | grep "is a function")" ] && RUN_ON_EXIT
		break
	fi

	[ "${INST_START_NEXT}" ] && INST_START="${INST_START_NEXT}" && INST_START_NEXT=
done
