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

prompt_template() {
	if [ "${PROMPT_TEMPLATE}" == "llama2" ]; then
		SYS_START="[INST] <<SYS>> "
		SYS_END=" <</SYS>>\n\n"
		INST_START_NEXT="[INST] "
		INST_END=" [/INST] "
	fi
}

init_prompt() {
	echo -ne "${SYS_START}" >> ./${ID}/prompt
	echo -n "${SYSTEM}" >> ./${ID}/prompt
	echo -ne "${SYS_END}" >> ./${ID}/prompt
}

llamacpp_fix() {
	PROMPT="$(cat ./${ID}/prompt)"
	echo "${PROMPT:1}" > ./${ID}/prompt
}

display_chat() {
	[ ! "${DEBUG}" ] && clear
	cat ./system | format_chat
	cat ./${ID}/prompt_full | format_chat
}

to_screen() {
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

format_chat() {
	while IFS= read -r LINE; do
		INTENT=
		[ "${LINE:0:${#USER_NAME}}:" == "${USER_NAME}:" ] && INTENT=1
		[ "${LINE:0:${#AI_NAME}}:" == "${AI_NAME}:" ] && INTENT=1
		[ "${INTENT}" ] && echo "${LINE}" | fmt -t
		[ ! "${INTENT}" ] && echo "${LINE}" | fmt
	done
}

context_size() {
	CTX_SIZE="$(cat ./log | grep -m1 n_ctx)"
	CTX_SIZE="$(return_4 ${CTX_SIZE})"
}

tokens_predict() {
	TOKENS="$(cat ./${ID}/log | grep generate:)"
	TOKENS="$(return_13 ${TOKENS})"
	((PREDICT=CTX_SIZE-TOKENS))
}

tokens_gen() {
	TOK_GEN_1="$(cat ./${ID}/log | grep "sample time")"
	TOK_GEN_1="$(return_8 ${TOK_GEN_1})"
	TOK_GEN_2="$(cat ./${ID}/log | grep "eval time")"
	TOK_GEN_2="$(return_9 ${TOK_GEN_1})"
	((PREDICT-=(TOK_GEN_1+TOK_GEN2)))
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
			--file ./${ID}/prompt 2> ./${ID}/log | tee ./${ID}/prompt_next | to_screen
	fi
	cp ./${ID}/prompt_next ./${ID}/prompt
	llamacpp_fix
	tokens_predict
	tokens_gen
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
	context_size
	tokens_predict
	tokens_gen
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

prompt_template

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
[ ! -f "./${ID}/cache" ] && cp ./cache ./${ID}/cache
[ ! -f "./${ID}/prompt" ] && cp ./prompt ./${ID}/prompt
[ ! -f "./${ID}/prompt_full" ] && touch ./${ID}/prompt_full
[ ! -f "./${ID}/log" ] && cp ./log ./${ID}/log && NO_TOKENS_GEN=1

context_size
tokens_predict
[ ! "${NO_TOKENS_GEN}" ] && tokens_gen

if [ "${PROMPT_TEMPLATE}" == "llama2" ]; then
	P1="$(cat ./prompt)"
	P2="$(cat ./${ID}/prompt)"
	[ "${#P1}" -ne "${#P2}" ] && INST_START="${INST_START_NEXT}"
fi

while true; do
	if [ "${INTERACTIVE}" ]; then
		display_chat
		echo -n "${USER_NAME} (${PREDICT}): "
		read INPUT
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
done
