[ ! -f "./Mistral-Nemo-Instruct-2407-Q8_0.gguf" ] && wget https://huggingface.co/bartowski/Mistral-Nemo-Instruct-2407-GGUF/resolve/main/Mistral-Nemo-Instruct-2407-Q8_0.gguf?download=true -O ./Mistral-Nemo-Instruct-2407-Q8_0.gguf

#PROMPT_TEMPLATE
BOS="<|im_start|>"
EOS="<|im_end|>"
SYS_START="${BOS} system "
SYS_END="${EOS}\n"
INST_START="${BOS} user "
INST_END="${EOS}\n"
REPL_START="${BOS} assistant"
REPL_END="${EOS}\n"
PROG="llama-cli --model ./Mistral-Nemo-Instruct-2407.Q8_0.gguf --ctx-size 32768 --temp 0.3"
#DEBUG=1

. ../sysprompts/sysprompt0.sh

