[ ! -f "./dolphin-2.9.3-mistral-nemo-Q8_0.gguf" ] && wget https://huggingface.co/cognitivecomputations/dolphin-2.9.3-mistral-nemo-12b-gguf/resolve/main/dolphin-2.9.3-mistral-nemo-Q8_0.gguf?download=true -O ./dolphin-2.9.3-mistral-nemo-Q8_0.gguf

#PROMPT_TEMPLATE
BOS="<|im_start|>"
EOS="<|im_end|>"
SYS_START="${BOS} system "
SYS_END="${EOS}\n"
INST_START="${BOS} user "
INST_START_NEXT=
INST_END="${EOS}\n"
REPL_START="${BOS} assistant"
REPL_END="${EOS}\n"

#DEBUG=1

PROG="llama-cli --ctx-size 32768 --override-kv tokenizer.ggml.pre=str:tekken --model ./dolphin-2.9.3-mistral-nemo-Q8_0.gguf"

. ../sysprompts/sysprompt0.sh
