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

help_screen() {
	echo
	echo "HELP"
	echo "----"
	echo "spit.sh v0.0.1"
	echo "${0} [ ID || help || -h || --help ]"
	echo
	echo "ID              an identifier for a new or existing chat session."
	echo "reset           remove all files generated for the initial prompt"
	echo "init            just generate the initial prompt files then exit"
	echo "help|-h|--help  show this here help screen"
	echo
}

exit_fail() {
	echo "ERROR: ${1}"
	exit ${2}
}

read_input() {
	echo
	echo -n "${USER_NAME} (${PREDICT}): "
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
	echo -ne "${INST_START}" >> ./${ID}/prompt
	echo -ne "${INPUT}" >> ./${ID}/prompt
	echo -ne "${INST_END}" >> ./${ID}/prompt
	echo -ne "${REPL_START}" >> ./${ID}/prompt
	echo -ne  "\n\n${USER_NAME}: ${INPUT}" >> ./${ID}/prompt_full
}

save_output() {
	echo -n "${GENERATED}" | tee -a ./${ID}/prompt >> ./${ID}/output
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
		echo -ne "${SYS_START}" >> ./prompt
		echo -ne "${SYSTEM}" >> ./prompt
		echo -ne "${SYS_END}" >> ./prompt
	fi
	init_prompt_chat >> ./prompt
}

display_chat() {
	if [ ! "${INTRO}" ]; then
		[ "${SYSTEM}" ] && echo "${SYSTEM}"
		init_prompt_chat
	else
		echo "${INTRO}"
	fi
	cat ./${ID}/prompt_full
}

get_tokens_predictable() {
	if [ -f "./${ID}/log" ]; then
		TOKENS="$(cat ./${ID}/log | grep generate:)"
		TOKENS="$(return_13 ${TOKENS})"
		((PREDICT=CTX_SIZE-TOKENS))
	else
		PREDICT=${CTX_SIZE}
	fi
}

get_tokens_generated() {
	if [ -f "./${ID}/log" ]; then
		TOK_GEN_1="$(cat ./${ID}/log | grep "sample time")"
		TOK_GEN_1="$(return_8 ${TOK_GEN_1})"
		TOK_GEN_2="$(cat ./${ID}/log | grep "eval time")"
		TOK_GEN_2="$(return_9 ${TOK_GEN_1})"
		((PREDICT-=(TOK_GEN_1+TOK_GEN_2)))
	fi
}

spit_predict() {
	PROG_P=(--prompt-cache ./${ID}/cache
		--prompt-cache-all
		--file ./${ID}/prompt
		--n_predict ${PREDICT}
		--simple-io
		"${REV_PROMPTS[@]}"
		--no-display-prompt)

	if [ "${DEBUG}" ]; then
		#echo -n "RUNNING: ${PROG[@]} ${PROG_P[@]}"
		"${PROG[@]}" "${PROG_P[@]}" 2> ./${ID}/log | tee ./${ID}/generated
		echo
		echo "EXIT WITH: ${PIPESTATUS[0]}"
		#cat ./${ID}/log
	else
		"${PROG[@]}" "${PROG_P[@]}" 2> ./${ID}/log | tee ./${ID}/generated
	fi
	GENERATED="$(cat ./${ID}/generated)"
	mv ./main.log ./${ID}
	get_tokens_predictable
	get_tokens_generated
}

spit_cache() {
	if [ "${BOS}" ]; then
		cp ./${ID}/prompt ./${ID}/prompt_tmp
		echo -ne "${BOS}" >> ./${ID}/prompt
	fi

	PROG_P=(--prompt-cache ./${ID}/cache
		--prompt-cache-all
		--file ./${ID}/prompt
		--n_predict 1
		--simple-io)

	if [ "${DEBUG}" ]; then
		#echo -n "RUNNING: ${PROG[@]} ${PROG_P[@]}"
		"${PROG[@]}" "${PROG_P[@]}" 2> ./${ID}/log
		echo
		echo "EXIT WITH: ${PIPESTATUS[0]}"
		#cat ./${ID}/log
	else
		"${PROG[@]}" "${PROG_P[@]}" 2> ./${ID}/log > /dev/null
	fi
	[ "${ID}" ] && mv ./main.log ./${ID}
	get_tokens_predictable
	get_tokens_generated
	[ "${BOS}" ] && mv ./${ID}/prompt_tmp ./${ID}/prompt
}

process_stop_sequence() {
	SEQ="$(detect_stop_sequence)"
	if [ "${SEQ}" ]; then
		SEQ_START="[${SEQ}]"
		SEQ_STOP="[/${SEQ}]"
		((STEPS=${#GENERATED}-${#SEQ_START}))
		for STEP in $(seq ${STEPS} -1 0); do
			((OFFSETL=STEP+${#SEQ_START}))
			((OFFSETR=${#GENERATED}-${OFFSETL}-${#SEQ_STOP}))
			if [ "${GENERATED:${STEP}:${#SEQ_START}}" == "${SEQ_START}" ]; then
				EXEC="${GENERATED:${OFFSETL}:${OFFSETR}}"
				break
			fi
		done
		"${SEQ}" "${EXEC}" | tee -a ./${ID}/prompt ./${ID}/output
	fi
}

stop_on_sequences() {
	for EACH in ${STOP_SEQUENCES[@]}; do
		REV_PROMPTS=(${REV_PROMPTS[@]} --reverse-prompt "[/${EACH}]")
	done
}

detect_stop_sequence() {
	for EACH in ${STOP_SEQUENCES[@]}; do
		_EACH="[/${EACH}]"
		((OFFSETD=${#GENERATED}-${#_EACH}))
		if [ "${GENERATED:${OFFSETD}:${#_EACH}}" == "${_EACH}" ]; then
			echo "${EACH}"
		fi
	done
}

stop_on_eos_token() {
	[ "${EOS}" ] && REV_PROMPTS=(${REV_PROMPTS[@]} --reverse-prompt ${EOS})
}

remove_eos_token() {
	if [ "${EOS}" ]; then
		((OFFSETR=${#GENERATED}-${#EOS}))
		if [ "${GENERATED:${OFFSETR}:${#EOS}}" == "${EOS}" ]; then
			GENERATED="${GENERATED:0:${OFFSETR}}"
			REMOVED_EOS_TOKEN=1
		fi
	fi
}

[ "${1}" == "help" ] || [ "${1}" == "-h" ] || [ "${1}" == "--help" ] && \
	help_screen && exit 0

[ ! "${1}" ] && help_screen && exit_fail "no ID given!" 1

[ ! -f "./spit.conf.sh" ] && exit_fail "./spit.conf.sh missing!" 1

. ./spit.conf.sh

[ ! "${PROG[0]}" ] && exit_fail "PROG not set!" 1
[ ! -f "${PROG[0]}" ] && exit_fail "${PROG[0]} not found!" 1
[ ! -x "${PROG[0]}" ] && exit_fail "${PROG[0]} not executable!" 1

[ "${EOS}" ] && stop_on_eos_token
stop_on_sequences

if [ ! -f "./cache" ] && [ "${SYSTEM}${CHAT[0]}" ]; then
	init_prompt
	[ ! "${DEBUG}" ] && [ "${INTERACTIVE}" ] && echo -n "creating cache..."
	spit_cache
	[ ! "${DEBUG}" ] && [ "${INTERACTIVE}" ] && echo "done."
fi

[ ! "${SYSTEM}" ] && touch ./prompt

ID="$(return_1 ${1})"
ID="$(basename ${ID})"

[ ! -d "./${ID}" ] && mkdir ./${ID}
[ ! -f "./${ID}/prompt" ] && cp ./prompt ./${ID}/prompt
[ ! -f "./${ID}/prompt_full" ] && touch ./${ID}/prompt_full
[ ! -f "./${ID}/cache" ] && [ -f "./cache" ] && cp ./cache ./${ID}/cache
[ ! -f "./${ID}/log" ] && [ -f "./log" ] && cp ./log ./${ID}/log

get_tokens_predictable

P1="$(cat ./prompt)"
P2="$(cat ./${ID}/prompt)"

[ "${#P2}" -gt "${#P1}" ] && get_tokens_generated

if [ "${INST_START_NEXT}" ] && [ ! "${CHAT}" ]; then
	[ "${#P2}" -gt "${#P1}" ] && INST_START="${INST_START_NEXT}"
fi
[ "${INST_START_NEXT}" ] && [ "${CHAT}" ] && INST_START="${INST_START_NEXT}"

if [ "${TEST}" ]; then
	TCOUNT=0
	INTERACTIVE=1
fi

[ ! "${DEBUG}" ] && [ "${INTERACTIVE}" ] && display_chat

while true; do

	if [ "${INTERACTIVE}" ]; then
		read_input
	elif [ "${2}" ]; then
		INPUT="${2}"
	elif [ -f "./${ID}/input" ]; then
		INPUT="$(cat ./${ID}/input)"
	fi

	[ ! "${INPUT}" ] && exit 0
	[ "${INPUT}" == ">file" ] && INPUT="$(cat ./${ID}/input)"

	save_input

	spit_cache
	if [ "$(cat ./${ID}/log | grep "prompt is too long")" ]; then
		exit_fail "prompt is too long!" 2
	fi

	[ "${INTERACTIVE}" ] && echo -n "${AI_NAME}:"
	echo -ne "\n\n${AI_NAME}:" >> ./${ID}/prompt_full

	echo -n > ./${ID}/output

	while true; do
		cp ./${ID}/prompt ./${ID}/prompt_last
		spit_predict
		remove_eos_token
		save_output
		rm -f ./${ID}/input
		if [ "${PREDICT}" -lt "1" ]; then
			exit_fail "reached maximum length!" 2
		elif [ "$(detect_stop_sequence)" ]; then
			process_stop_sequence
			spit_cache
		elif [ "${REMOVED_EOS_TOKEN}" ]; then
			REMOVED_EOS_TOKEN=
			break
		elif [ "$(cat ./${ID}/log | grep "[end of text]")" ]; then
			break
		fi
	done

	cat ./${ID}/output >> ./${ID}/prompt_full

	((LAST_CHAR=${#GENERATED}-1))
	if [ "${GENERATED:${LAST_CHAR}}" != "$(echo)" ] || [ ! "${GENERATED}" ]; then
		echo
	fi


	echo -ne "${REPL_END}" >> ./${ID}/prompt

	[ ! "${INTERACTIVE}" ] && echo && break

	[ "${INST_START_NEXT}" ] && INST_START="${INST_START_NEXT}" && INST_START_NEXT=
done
