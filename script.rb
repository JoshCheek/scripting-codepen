# for interacting with us
require_relative 'user'
user = User.new $stdin, $stdout

# get the resource to add to the pens
user.heading 'Enter the resource to add to the pens'
user.puts "Example: https://codepen.io/josh_cheek/pen/eLqGGJ"
resource = user.gets
user.puts "Resource: #{resource.inspect}"

# for controlling chrome
user.heading 'Loading Chrome'
require "selenium-webdriver"
require_relative 'browser'
browser = Browser.new Selenium::WebDriver.for :chrome

browser.visit "http://codepen.io"
browser.click '#login-button'

begin
  user.heading 'Login to codepen and then press any key to continue'
  user.press_any_key

  user.heading 'First getting the list of pens'
  browser.visit 'https://codepen.io/pens/mypens/'
  sleep 2 # idk, sometimes it takes too long to put the content on the page -.-

  pens = []
  loop do
    hrefs = browser.all('.single-pen a.cover-link') { |a| a[:href] }
    pens.concat hrefs
    puts hrefs
    break unless browser.click 'a[data-direction=next]'
  end

  user.heading 'Total number of pens'
  user.puts pens.size

  user.heading "Now we'll go to each pen and potentially link a fixup script"
  pens.each do |pen|
    browser.visit pen
    next unless user.ask "Add resource to this page?"

    browser.click '#settings-pane-css'                        # opens the css settings
    pre_resources = browser.all '.external-resource-url-row'  # the initial of resources
    browser.click '#add-css-resource'                         # add a new row to amke sure there's an open spot for it
    post_resources = browser.all '.external-resource-url-row' # the new resources
    new_resources  = post_resources - pre_resources           # get the difference
    if new_resources.length != 1
      user.error "uhm.... something went wrong, was expecting to find a new css resource after I clicked the 'add another resource' button, but I found #{new_resources.length} instead!"
      user.error "skipping this pen *shrug*"
      next
    end
    browser.type resource, into: [new_resources.first, 'input']

    browser.click '#item-settings-modal input.save-and-close'
    user.press_any_key 'Press any key to go to the next pen'
    # browser.click '#run' # sigh, this can fail b/c the overlay is still on top of it
  end
rescue StandardError => err
  user.error err.inspect
  require 'pry'
  binding.pry
end

user.heading 'All done!'
browser.quit
