## 🤖 **tGPT** - Your coding assistant in terminal

<p align="center">
	<a href="https://github.com/rutvik110/tGPT"  target="_blank"><img src="https://img.shields.io/pub/v/terminalgpt.svg" alt="Pub.dev Badge"></a>
	<a href="https://opensource.org/licenses/MIT" rel="noopener" target="_blank"><img src="https://img.shields.io/badge/license-MIT-purple.svg" alt="MIT License Badge"></a>
</p>



https://user-images.githubusercontent.com/65209850/226115287-33c1b39c-5350-42d4-8a9e-09049ac87a1e.mp4



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

## Support the project

💕 **Sponsor on github**

[!["Buy Me A Coffee"](https://www.buymeacoffee.com/assets/img/custom_images/orange_img.png)](https://www.buymeacoffee.com/takrutvik)
