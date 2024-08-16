[ ! -f "Meta-Llama-3.1-8B-Instruct-Q8_0.gguf" ] && wget https://huggingface.co/lmstudio-community/Meta-Llama-3.1-8B-Instruct-GGUF/resolve/main/Meta-Llama-3.1-8B-Instruct-Q8_0.gguf?download=true -O ./Meta-Llama-3.1-8B-Instruct-Q8_0.gguf

#PROMPT_TEMPLATE
BOT="<|begin_of_text|>"
EOT="<|eot_id|>"
BOS="${BOT}"
EOS="${EOT}"
SYS_START="${BOT}<|start_header_id|>system<|end_header_id|>\n\n"
SYS_END="${EOT}"
INST_START="<|start_header_id|>user<|end_header_id|>\n\n"
INST_END="${EOT}"
REPL_START="<|start_header_id|>assistant<|end_header_id|>\n\n"
REPL_END="${EOT}"
PROG="llama-cli --model ./Meta-Llama-3.1-8B-Instruct-Q8_0.gguf --ctx-size 32768"
[ -e "/dev/nvidia0" ] && PROG="${PROG} -ngl 10000"
#DEBUG=1

. ../sysprompts/sysprompt0.sh
