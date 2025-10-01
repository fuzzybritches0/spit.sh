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
STOP_SEQUENCES=("WIKI" "SELECT_INDEX" "SEARCH" "READ_URL" "EXECUTE")
PROG="llama-cli --model ./Meta-Llama-3.1-8B-Instruct-Q8_0.gguf --temp 0.4"
#DEBUG=1

. ../sysprompts/sysprompt0.sh
