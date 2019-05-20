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
bot.send_photo(chat_id=chat_id, caption=image_text, photo=open(image, 'rb'))
#from telegram.ext import Updater
#updater = Updater(token='716850847:AAEFrKfYrv3iXFc7RilG3UqxueJA5yAvGZY', use_context=True)




