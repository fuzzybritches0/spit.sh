#PROMPT_TEMPLATE
CTX_SIZE=32768
USER_NAME="User"
AI_NAME="Assistant"
BOS="<s>"
EOS="</s>"
SYS_START=
SYS_END=
INST_START="${BOS} [INST] "
INST_START_NEXT=
INST_END=" [/INST]"
REPL_START=
REPL_END="${EOS}"
STOP_SEQUENCES=()

DEBUG=
INTERACTIVE=1

PROG=("./main"
--ctx_size ${CTX_SIZE}
--keep -1
--repeat_last_n 512
--repeat_penalty 1.17647
--no-penalize-nl
--temp 0.5
--top_k 40
--top_p 0.5
--threads 12
--verbose-prompt
--model "./mixtral-8x7b-instruct-v0.1.Q8_0.gguf")
