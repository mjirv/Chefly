import sys
from selenium import webdriver
from selenium.webdriver.common.keys import Keys
from time import sleep

# Called like python instacart_driver.py "email@address" "password" "{'eggs':1, 'chicken breast':2}"
USERNAME = sys.argv[1]
PASSWORD = sys.argv[2]
GROCERY_ITEMS = eval(sys.argv[3])
CHROMEDRIVER_PATH = sys.argv[4]

def login():
    # Sometimes it takes you to a different landing page...
    try:
        login_button = br.find_element_by_css_selector('a.log-in')
        login_button.click()
    except:
        login_button = br.find_element_by_css_selector('a.ic-btn.ic-btn-success')
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
    sleep(1)
    search_bar.clear()
    sleep(1)
    search_bar.send_keys(item, Keys.RETURN)

def add_item(item):
    #try:
        item_button = br.find_element_by_css_selector('li.item.has-details')
        item_button.click()
        add_button = br.find_element_by_css_selector('button.ic-btn.ic-btn-success.ic-btn-lg.ic-btn-block')
        add_button.click()

        num_items = GROCERY_ITEMS[item]

        if num_items > 1:
            #data_value = str(num_items)
            data_value = "custom"
            #if num_items > 10:
            #    data_value = "custom"

            sleep(1)

            # put this in a try since if the item is already added, add_button will already be open
            try:
                add_button = br.find_element_by_css_selector('button.ic-btn.ic-btn-lg.ic-btn-block.ic-btn-success')
                add_button.click()
            except:
                current_number = int(br.find_element_by_css_selector('div.icDropdownItem.is-selected').get_attribute('data-value')) + num_items
                #if current_number > 10:
                #    data_value = "custom"
                #else:
                #    data_value = str(current_number)

            number_selector = br.find_element_by_xpath("//div[@data-value=\"{}\"]".format(data_value))
            number_selector.click()

            input_box = br.find_element_by_css_selector('input.ic-input-lg')
            input_box.send_keys(str(num_items), Keys.RETURN)

            #if num_items > 10:

            submit_button = br.find_element_by_css_selector('button.ic-btn.ic-btn-success.ic-btn-lg.ic-btn-block')
            submit_button.click()
            sleep(1)

    #except Exception as e:
    #    print(e)
    #    sleep(10)

            exit_button = br.find_element_by_css_selector('i.ic-icon.ic-icon-x-bold.icModalClose')
            exit_button.click()
            sleep(1)

# Open the webdriver
global br
br = webdriver.Chrome(CHROMEDRIVER_PATH)
br.implicitly_wait(10)
br.get("https://instacart.com")

# Set things up
login()
change_store()
sleep(1)

# Start searching
for item in GROCERY_ITEMS:
    search(item)
    sleep(2)
    add_item(item)

# Close up
sleep(1)
br.close()
