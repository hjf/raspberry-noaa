#!/usr/bin/python3
import sys
token=sys.argv[1]
chat_id=sys.argv[2]
image=sys.argv[3]
image_text=sys.argv[4]
import logging
logging.basicConfig(level=logging.DEBUG,
                    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s')

import telegram
bot = telegram.Bot(token=token)
#print(bot.get_me())
bot.send_photo(chat_id=chat_id, caption=image_text, photo=open(image, 'rb'),timeout=60)
#from telegram.ext import Updater




