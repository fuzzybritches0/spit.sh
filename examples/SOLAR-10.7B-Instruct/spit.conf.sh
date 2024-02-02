USER_NAME="User"
AI_NAME="Assistant"

#PROMPT TEMPLATE
CTX_SIZE=4096
SYS_START=
SYS_END=
BOS="<s>"
EOS="</s>"
INST_START="${BOS} ### ${USER_NAME}:\n"
INST_START_NEXT=
INST_END=
REPL_START="\n### ${AI_NAME}:\n"
REPL_END="${EOS}\n"
STOP_SEQUENCES=()

DEBUG=
INTERACTIVE="1"

PROG=("./main"
--ctx_size "${CTX_SIZE}"
--keep "-1"
--repeat_last_n "512"
--repeat_penalty "1.17647"
--temp ".8"
--top_k "40"
--top_p "0.5"
--threads "12"
--model "./solar-10.7b-instruct-v1.0.Q8_0.gguf")
