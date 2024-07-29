# I have a system of 128GB of ram, and an AMD Ryzen 9 7900X 12-Core Processor. The generation, however, is very slow. I get about one token per two seconds.

[ ! -f "./Mistral-Large-Instruct-2407.Q6_K-00001-of-00005.gguf" ] && wget https://huggingface.co/legraphista/Mistral-Large-Instruct-2407-IMat-GGUF/resolve/main/Mistral-Large-Instruct-2407.Q6_K/Mistral-Large-Instruct-2407.Q6_K-00001-of-00005.gguf?download=true -O Mistral-Large-Instruct-2407.Q6_K-00001-of-00005.gguf

[ ! -f "./Mistral-Large-Instruct-2407.Q6_K-00002-of-00005.gguf" ] && wget https://huggingface.co/legraphista/Mistral-Large-Instruct-2407-IMat-GGUF/resolve/main/Mistral-Large-Instruct-2407.Q6_K/Mistral-Large-Instruct-2407.Q6_K-00002-of-00005.gguf?download=true -O Mistral-Large-Instruct-2407.Q6_K-00002-of-00005.gguf

[ ! -f "./Mistral-Large-Instruct-2407.Q6_K-00003-of-00005.gguf" ] && wget https://huggingface.co/legraphista/Mistral-Large-Instruct-2407-IMat-GGUF/resolve/main/Mistral-Large-Instruct-2407.Q6_K/Mistral-Large-Instruct-2407.Q6_K-00003-of-00005.gguf?download=true -O Mistral-Large-Instruct-2407.Q6_K-00003-of-00005.gguf

[ ! -f "./Mistral-Large-Instruct-2407.Q6_K-00004-of-00005.gguf" ] && wget https://huggingface.co/legraphista/Mistral-Large-Instruct-2407-IMat-GGUF/resolve/main/Mistral-Large-Instruct-2407.Q6_K/Mistral-Large-Instruct-2407.Q6_K-00004-of-00005.gguf?download=true -O Mistral-Large-Instruct-2407.Q6_K-00004-of-00005.gguf

[ ! -f "./Mistral-Large-Instruct-2407.Q6_K-00005-of-00005.gguf" ] && wget https://huggingface.co/legraphista/Mistral-Large-Instruct-2407-IMat-GGUF/resolve/main/Mistral-Large-Instruct-2407.Q6_K/Mistral-Large-Instruct-2407.Q6_K-00005-of-00005.gguf?download=true -O Mistral-Large-Instruct-2407.Q6_K-00005-of-00005.gguf

#PROMPT_TEMPLATE
BOS="<|im_start|>"
EOS="<|im_end|>"
SYS_START="${BOS} system "
SYS_END="${EOS}\n"
INST_START="${BOS} user "
INST_END="${EOS}\n"
REPL_START="${BOS} assistant"
REPL_END="${EOS}\n"
PROG="llama-cli --model ./parts/Mistral-Large-Instruct-2407.Q6_K-00001-of-00005.gguf --ctx-size 32768 --temp 0.3"
#DEBUG=1

. ../spit/sysprompts/sysprompt0.sh

