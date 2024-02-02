#PROMPT_TEMPLATE
CTX_SIZE=8192
USER_NAME="${USER^}"
AI_NAME="Sam"
BOS=
EOS="<|end_of_turn|>"
SYS_START=
SYS_END=
INST_START="GPT4 Correct User: "
INST_START_NEXT=
INST_END="${EOS}"
REPL_START="GPT4 Correct Assistant:"
REPL_END="${EOS}"
LLAMACPP_FIX=
OFFSET_FIX_TOKENS=()
OFFSET=1
STOP_SEQUENCES=("EXECUTE")

DEBUG=
INTERACTIVE=1

PROG=("./main"
--ctx_size ${CTX_SIZE}
--keep -1
--repeat_last_n 512
--repeat_penalty 1.17647
--no-penalize-nl
--temp 0
--top_k 40
--top_p 0.5
--threads 12
--verbose-prompt
--model "./openchat-3.5-0106.Q8_0.gguf")
