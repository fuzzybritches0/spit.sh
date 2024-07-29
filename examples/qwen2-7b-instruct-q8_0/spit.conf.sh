[ ! -f "./qwen2-7b-instruct-q8_0.gguf" ] && wget https://huggingface.co/Qwen/Qwen2-7B-Instruct-GGUF/resolve/main/qwen2-7b-instruct-q8_0.gguf?download=true -O ./qwen2-7b-instruct-q8_0.gguf

#PROMPT_TEMPLATE
BOS="<|im_start|>"
EOS="<|im_end|>"
SYS_START="${BOS} system "
SYS_END="${EOS}\n"
INST_START="${BOS} user "
INST_END="${EOS}\n"
REPL_START="${BOS} assistant"
REPL_END="${EOS}\n"
STOP_SEQUENCES=("WIKI" "SELECT_INDEX" "SEARCH" "READ_URL" "EXECUTE")
PROG="./llama-cli --model ./qwen2-7b-instruct-q8_0.gguf"
#DEBUG=1

. ../sysprompts/sysprompt0.sh

