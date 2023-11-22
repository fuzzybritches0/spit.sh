#!/bin/bash
# SPDX-License-Identifier: GPL-2.0

return_1() {
	echo "${1}"
}

return_4() {
	echo "${4}"
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
	echo "${0} [ ID || reset || init || help || -h || --help ]"
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
		echo -ne "${SYS_START}" >> ./${ID}/prompt
		echo -ne "${SYSTEM}" >> ./${ID}/prompt
		echo -ne "${SYS_END}" >> ./${ID}/prompt
	fi
	init_prompt_chat >> ./${ID}/prompt
}

llamacpp_fix() {
	PROMPT="$(cat ./${ID}/prompt)"
	echo "${PROMPT:1}" > ./${ID}/prompt
}

display_chat() {
	if [ ! "${INTRO}" ]; then
		echo "${SYSTEM}"
		init_prompt_chat
	else
		echo "${INTRO}"
	fi
	cat ./${ID}/prompt_full
}

stream_output() {
	if [ "${DEBUG}" ]; then
		cat
	else
		count=0
		while IFS= read -N1 C; do
			((count++))
			if [ "${count}" -gt "${JUMP}" ]; then
				printf "%s" "${C}"
			fi
		done
	fi
}

get_context_size() {
	CTX_SIZE="$(cat ./log | grep -m1 n_ctx)"
	CTX_SIZE="$(return_4 ${CTX_SIZE})"
}

get_tokens_predictable() {
	TOKENS="$(cat ./${ID}/log | grep generate:)"
	TOKENS="$(return_13 ${TOKENS})"
	((PREDICT=CTX_SIZE-TOKENS))
}

get_tokens_generated() {
	TOK_GEN_1="$(cat ./${ID}/log | grep "sample time")"
	TOK_GEN_1="$(return_8 ${TOK_GEN_1})"
	TOK_GEN_2="$(cat ./${ID}/log | grep "eval time")"
	TOK_GEN_2="$(return_9 ${TOK_GEN_1})"
	((PREDICT-=(TOK_GEN_1+TOK_GEN2)))
}

jump_offset_fix_resume() {
	if [ "${JUMP_OFFSET_1}" ]; then
		CON_COUNT="$(cat ./1/prompt | grep -o "$(echo -ne ${REPL_START})" | wc -l)"
		((JUMP_OFFSET+=JUMP_OFFSET_1 * CON_COUNT))
	fi
}

jump_offset_fix() {
	((JUMP_OFFSET+=JUMP_OFFSET_1))
}

jump_n() {
	PROMPT="$(cat ./${ID}/prompt)"
	JUMP=${#PROMPT}
}

spit_predict() {
	if [ "${DEBUG}" ]; then
		"${PROG[@]}" --prompt-cache ./${ID}/cache --prompt-cache-all --n_predict ${PREDICT} "${REV_PROMPTS[@]}" \
			--file ./${ID}/prompt 2> ./${ID}/log | tee ./${ID}/prompt_next
		echo
		echo "EXIT WITH: ${PIPESTATUS[0]}"
		cat ./${ID}/log
	else
		jump_n
		"${PROG[@]}" --prompt-cache ./${ID}/cache --prompt-cache-all --n_predict ${PREDICT} "${REV_PROMPTS[@]}" \
			--file ./${ID}/prompt 2> ./${ID}/log | tee ./${ID}/prompt_next | stream_output
	fi
	cp ./${ID}/prompt_next ./${ID}/prompt
	mv ./main.log ./${ID}
	[ "${LLAMACPP_FIX}" ] && llamacpp_fix
	get_tokens_predictable
	get_tokens_generated
}

spit_cache() {
	if [ "${DEBUG}" ]; then
		"${PROG[@]}" --prompt-cache ./${ID}/cache --file ./${ID}/prompt \
			--n_predict 1 2> ./${ID}/log
		echo
		echo "EXIT WITH: ${PIPESTATUS[0]}"
		cat ./${ID}/log
	else
		"${PROG[@]}" --prompt-cache ./${ID}/cache --file ./${ID}/prompt \
			--n_predict 1 2> ./${ID}/log > /dev/null
	fi
	[ "${ID}" ] && mv ./main.*.log ./${ID}/logs/
	get_context_size
	get_tokens_predictable
	get_tokens_generated
}

shift_prompt() {
	FULL="$(cat ./${ID}/prompt | wc -l)"
	SYSPROMPT="$(cat ./system | wc -l)"
	((SYSPROMPT=+2))
	((HALF-=SYSPROMPT))
	((HALF=FULL/2))
	PROMPT="$(tail -n ${HALF} ./${ID}/prompt)"
	init_prompt
	echo -n "${PROMPT}" >> ./${ID}/prompt
}

[ "${1}" == "help" ] || [ "${1}" == "-h" ] || [ "${1}" == "--help" ] && \
	help_screen && exit 0

[ ! -f "./spit.rc" ] && exit_fail "./spit.rc missing!" 1
[ ! -f "./system" ] && exit_fail "./system missing!" 1

if [ "${1}" == "reset" ]; then
	rm -rf cache log prompt
	echo "reset"
	exit 0
fi

. ./spit.rc

[ ! "${PROG}" ] && exit_fail "PROG not set!" 1

SYSTEM="$(cat ./system)"

if [ ! -f "./cache" ]; then
	init_prompt
	[ ! "${DEBUG}" ] && [ "${INTERACTIVE}" ] && echo -n "creating cache..."
	spit_cache
	[ ! "${DEBUG}" ] && [ "${INTERACTIVE}" ] && echo "done."
fi

[ "${1}" == "init" ] && exit 0

[ ! "${1}" ] && help_screen && exit_fail "no ID given!" 1

ID="$(return_1 ${1})"
ID="$(basename ${ID})"

[ ! -d "./${ID}" ] && mkdir ./${ID}
[ ! -d "./${ID}/logs" ] && mkdir ./${ID}/logs
[ ! -f "./${ID}/cache" ] && cp ./cache ./${ID}/cache
[ ! -f "./${ID}/prompt" ] && cp ./prompt ./${ID}/prompt
[ ! -f "./${ID}/prompt_full" ] && touch ./${ID}/prompt_full
[ ! -f "./${ID}/log" ] && cp ./log ./${ID}/log && NO_TOKENS_GEN=1

get_context_size
get_tokens_predictable
[ ! "${NO_TOKENS_GEN}" ] && get_tokens_generated

if [ "${INST_START_NEXT}" ] && [ ! "${CHAT}" ]; then
	P1="$(cat ./prompt)"
	P2="$(cat ./${ID}/prompt)"
	[ "${#P1}" -ne "${#P2}" ] && INST_START="${INST_START_NEXT}"
fi

[ "${INST_START_NEXT}" ] && [ "${CHAT}" ] && INST_START="${INST_START_NEXT}"

jump_offset_fix_resume

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
	echo -ne "${INST_START}" >> ./${ID}/prompt
	echo -n "${INPUT}" >> ./${ID}/prompt
	echo -ne "${INST_END}" >> ./${ID}/prompt
	echo "${USER_NAME}: ${INPUT}" >> ./${ID}/prompt_full
	[ "${INTERACTIVE}" ] && echo -n "${AI_NAME}:"

	cp ./${ID}/prompt ./${ID}/prompt_last

	while true; do
		spit_predict
		if [ "$(cat ./${ID}/log | grep "prompt is too long")" ]; then
			cp ./${ID}/prompt_last ./${ID}/prompt
			shift_prompt
			spit_cache
		elif [ "${PREDICT}" -eq "0" ] && [ ! "$(cat ./${ID}/log | grep "[end of text]")" ]; then
			shift_prompt
			spit_cache
		else
			break
		fi
	done

	PROMPT="$(cat ./${ID}/prompt)"
	PROMPT_LAST="$(cat ./${ID}/prompt_last)"
	((CUT_OFFSET=${#PROMPT}-${#PROMPT_LAST}))
	PREDICTED="${PROMPT:${#PROMPT_LAST}:${CUT_OFFSET}}"
	echo "${PREDICTED}" > ./${ID}/predicted
	echo "${AI_NAME}:${PREDICTED}" >> ./${ID}/prompt_full
	[ ! "${INTERACTIVE}" ] && echo && break

	[ "${INST_START_NEXT}" ] && INST_START="${INST_START_NEXT}" && INST_START_NEXT=

	jump_offset_fix
done
