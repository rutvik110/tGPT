## 🤖 **tGPT** - Your coding assistant in terminal

tGPT offers simple terminal experience which can speed up your coding as you won't have to leave your terminal again. 

🔑 You can use tGPT with your own OpenAI api key. Your key and all of your data is stored locally on your device.

💬 tGPT saves your conversations locally, so you never loose your conversation history.

tGPT aims to be as simple as possible while helping you get your questions answered.

# Getting Started 

tGPT is an dart cli application. Make sure you've dart sdk installed on your system.

If you don't have dart installed, follow the [installation guide](https://dart.dev/get-dart) to install dart.

Once dart is installed on your system, you can run the program in dev through below command,

```
> dart run bin/terminalgpt.dart
```

For easy access on your system from anywhere, activate the tGPT globally on your system by running folowing command,

```
> dart pub global activate --source path .
```
Once activated, you can use it as follow,

```
> tgpt
```


tGPT on first run will ask for your OpenAI api key which you can set up to then use tGPT. 

⌨️ tGPT cli commands,

| Command | Description |
| --- | --- |
| -i, --input | Specify input(if not provided, tGPT will ask on the run) |
| -u, --updateKey | Update api key(optinal, is asked on the first run) |
| -m, --model | Choose the chat model (optinal, is asked on the first run) |
| -c --clear | Clear chat history |
| -h, --help  | Shows available commands |
|  |  |


# 🛣️ Roadmap 

✨ Improve the output with better formatting for better readability

🔍 Search for past conversations
