# setup state (for saving progress)
require_relative 'state'
filename = File.realdirpath 'state.json', __dir__
state = State.new filename

# object to manage interacting with us
require_relative 'user'
user = User.new $stdin, $stdout

# get the resource to add to the pens
user.heading 'Enter the resource to add to the pens (eg with the fixup code)'
user.puts "Example: https://codepen.io/josh_cheek/pen/eLqGGJ"
state.resource = user.gets(state.resource)
user.puts "Resource: #{state.resource.inspect}"

# for controlling chrome
user.heading 'Loading Chrome'
require "selenium-webdriver"
require_relative 'browser'
browser = Browser.new Selenium::WebDriver.for :chrome
browser.visit "http://codepen.io"
browser.click '#login-button'

# login
user.heading 'Login to codepen and then press any key to continue'
user.press_any_key

# maybe get the list of pens
user.heading 'First getting the list of pens'

if !state.pens_loaded? || !user.ask("You already have #{state.num_pens} saved, use these?")
  browser.visit 'https://codepen.io/pens/mypens/'
  sleep 2 # idk, sometimes it takes too long to put the content on the page -.-
  state.clear_pens

  loop do
    hrefs = browser.all('.single-pen a.cover-link') { |a| a[:href] }
    state.add_pens hrefs
    puts hrefs
    break unless browser.click 'a[data-direction=next]'
  end

  user.puts 'Total number of pens', state.num_pens
end



user.heading "Now we'll go to each pen and potentially link the resource"
state.each_pen do |index:, href:, evaluated:, added:|
  # skip work we've already done
  user.puts "#{index}\t#{href}"
  if evaluated
    added_str = added ? "added" : "not added"
    user.puts "\tAlready evaluated (#{added_str}), skipping"
    next
  end

  # prompt whether to add the resource
  browser.visit href
  do_add = user.ask "\tAdd resource to this page?"
  if !do_add
    state.update_pen href, evaluated: true, added: false
    next
  end

  # add the resource
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
  browser.type state.resource, into: [new_resources.first, 'input']

  browser.click '#item-settings-modal input.save-and-close'
  state.update_pen href, evaluated: true, added: true
  user.press_any_key "\tPress any key to go to the next pen"
  # browser.click '#run' # sigh, this can fail b/c the overlay is still on top of it
end

user.heading 'All done!'
browser.quit
