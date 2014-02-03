import calendar
import dateutil.parser
import urllib2

from PhotoFeedItem import PhotoFeedItem
from bs4 import BeautifulSoup
from datetime import datetime

FEED_TITLE = 'Big Picture'
FEED_DESCRIPTION = 'News Stories in Photographs from the Boston Globe'
FEED_URL = 'http://feeds.boston.com/boston/bigpicture/index'

def get_photoitem_from_block(item_dict, block):
    photo_item = PhotoFeedItem()
    photo_item.title = item_dict['title']
    photo_item.pub_date = item_dict['pubdate']
    photo_item.page_url = item_dict['page_url']
    photo_item.photo_url = block.find('img', {'class' : 'bpImage'})['src']
    photo_item.caption = block.find('div', {'class' : 'bpCaption'}).text
    return photo_item

raw_page = urllib2.urlopen(FEED_URL).read()

soup = BeautifulSoup(raw_page)
item_elements = soup.find_all('item')

series_title  = ''
series_link = ''

feed_items = []
photo_items = []

for item in item_elements:
    temp_date = item.find('pubdate').text

    item_dict = {
        'title'    : item.find('title').text,
        'page_url' : item.find('link').text,
        'pubdate'  : calendar.timegm(dateutil.parser.parse(temp_date).utctimetuple())
    }
    feed_items.append(item_dict)

for item in feed_items:
    raw_photo_page = urllib2.urlopen(item['page_url']).read()
    photo_page_soup = BeautifulSoup(raw_photo_page)

    [
        photo_items.append(get_photoitem_from_block(item, photo_block))
        for photo_block
        in photo_page_soup.find_all('div', { 'class' : 'bpImageTop'})
    ]

    [
        photo_items.append(get_photoitem_from_block(item, photo_block))
        for photo_block
        in photo_page_soup.find_all('div', { 'class' : 'bpBoth'})
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
        <parentLink>%s</parentLink>
        <pubDate>%s</pubDate>
        <description>%s</description>
    </item>""" % (item.title, item.photo_url, item.page_url, item.pub_date, item.caption)

print '</channel>'
