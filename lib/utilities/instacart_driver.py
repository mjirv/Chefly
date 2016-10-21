import sys
from selenium import webdriver
from selenium.webdriver.common.keys import Keys
from time import sleep

# Called like python instacart_driver.py "email@address" "password" "{'eggs':1, 'chicken breast':2}"
USERNAME = sys.argv[1]
PASSWORD = sys.argv[2]
GROCERY_ITEMS = eval(sys.argv[3])

def login():
    login_button = br.find_element_by_css_selector('a.log-in')
    login_button.click()

    username_box = br.find_element_by_css_selector('fieldset.email > input')
    password_box = br.find_element_by_css_selector('fieldset.password > input')

    username_box.send_keys(USERNAME)
    password_box.send_keys(PASSWORD, Keys.RETURN)

def change_store():
    store_button = br.find_element_by_css_selector('a.primary-nav-link')
    store_button.click()

    sleep(2)

    first_store = br.find_element_by_css_selector('a.retailer-option-inner-wrapper')
    first_store.click()

def search(item):
    search_bar = br.find_element_by_css_selector('input.tt-input.search-field')
    search_bar.clear()
    search_bar.send_keys(item, Keys.RETURN)

def add_item():
    item = br.find_element_by_css_selector('li.item.has-details')
    item.click()
    sleep(3)
    add_button = br.find_element_by_css_selector('button.ic-btn.ic-btn-success.ic-btn-lg.ic-btn-block')
    add_button.click()
    exit_button = br.find_element_by_css_selector('i.ic-icon.ic-icon-x-bold.icModalClose')
    exit_button.click()

# Open the webdriver
global br
br = webdriver.Chrome()
br.get("https://instacart.com")

# Set things up
login()
sleep(4)
change_store()
sleep(1)

# Start searching
for item in GROCERY_ITEMS:
    search(item)
    sleep(2)
    add_item()

# Close up
sleep(5)
br.close()
