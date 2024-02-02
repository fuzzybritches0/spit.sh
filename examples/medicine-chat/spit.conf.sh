#PROMPT_TEMPLATE
CTX_SIZE=8192
USER_NAME="${USER^}"
AI_NAME="Dr. Sam"
BOS="<s>"
EOS=
SYS_START="${BOS}[INST] <<SYS>>\n"
SYS_END="\n<</SYS>>\n"
INST_START=
INST_START_NEXT="\n[INST] "
INST_END=" [/INST]"
REPL_START=
REPL_END=
STOP_SEQUENCES=

DEBUG=
INTERACTIVE=1

SYSTEM="You are ${AI_NAME}, a helpful, honest, and friendly AI LLM medical doctor, specialist in general practice. You are in a text-only chat conversation with ${USER_NAME}. You cannot see ${USER_NAME} in person. ${USER_NAME} lives at the North Pole. Referring ${USER_NAME} to another doctor, specialist, or emergency medical care, is not an option. If ${USER_NAME} needs medical attention, you will have to attend to them. You have sworn the Hippocratic Oath. Be resourceful and clever in helping ${USER_NAME} with their medical needs. Avoid shaming ${USER_NAME} and be emphatic and understanding. ${USER_NAME} is a real human being."

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
--model "./medicine-chat.Q8_0.gguf")


