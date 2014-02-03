import calendar
import dateutil.parser
import urllib2

from PhotoFeedItem import PhotoFeedItem
from bs4 import BeautifulSoup
from datetime import datetime

FEED_TITLE = 'In Focus'
FEED_DESCRIPTION = 'In Focus, a News Photo Blog with Alan Taylor, from The Atlantic'
FEED_URL = 'http://feeds.feedburner.com/theatlantic/infocus?format=xml'

def get_photofeeditem_from_block(item, block):
    photoitem = PhotoFeedItem()
    photoitem.title = item['title']
    photoitem.pub_date = item['pub_date']
    photoitem.page_url = item['page_url']
    photoitem.photo_url = block.find('img', {'class' : 'ifImg'})['src']
    photoitem.caption = block.find('div', {'class' : 'imgCap'}).text
    return photoitem

feed_items = []
photo_items = []

raw_page = urllib2.urlopen(FEED_URL).read()

soup = BeautifulSoup(raw_page)
items = soup.find_all('item')
photo_page_urls = []

for item in items:
    temp_date = item.find('pubdate').text

    item_dict = {
        'title' : item.find('title').text,
        'page_url' : item.find('link').text,
        'pub_date' : calendar.timegm(dateutil.parser.parse(temp_date).utctimetuple())
    }
    feed_items.append(item_dict)

for item in feed_items:
    raw_photo_page = urllib2.urlopen(item['page_url']).read()
    photo_page_soup = BeautifulSoup(raw_photo_page)
    photo_blocks = photo_page_soup.find_all('span', { 'class' : 'if1024'})

    [
        photo_items.append(get_photofeeditem_from_block(item, block))
        for block
        in photo_blocks
    ]


# RSS output
print '<?xml version="1.0" encoding="UTF-8"?>'
print '<channel>'
print '  <title>%s</title>' % FEED_TITLE
print '  <description>%s</description>' % FEED_DESCRIPTION
for item in photo_items:
    print """
    <item>
        <title>%s</title>
        <link>%s</link>
        <pubDate>%s</pubDate>
        <description>%s</description>
    </item>""" % (item.title, item.photo_url, item.pub_date, item.caption)

print '</channel>'
