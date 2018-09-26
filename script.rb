# setup
require "selenium-webdriver"
driver = Selenium::WebDriver.for :chrome

driver.navigate.to "http://codepen.io"
driver.find_element(id: 'login-button').click

begin
  puts "----- login to codepen and then press return to continue --"
  gets

  puts "----- first getting the list of pens -----"
  driver.navigate.to 'https://codepen.io/pens/mypens/'
  pens = []
  loop do
    begin
      anchors = driver.find_elements(:css, '.single-pen a.cover-link')
      hrefs   = anchors.map { |a| a[:href] }
      pens.concat hrefs
      puts hrefs
    rescue Selenium::WebDriver::Error::StaleElementReferenceError
      retry
    end
    begin
      next_page = driver.find_element :css, 'a[data-direction=next]'
    rescue Selenium::WebDriver::Error::NoSuchElementError
      break
    end
    next_page.click
  end

  pens.uniq! # shouldn't be necessary, but we'll do it for good measure

  puts "----- total number of pens -----", pens.size


  puts "----- now we'll go to each pen and potentially link a fixup script -----"
  def get_bool(prompt)
    print "#{prompt} (y/n)"
    answer = gets.downcase.strip
    if answer != 'y' && answer != 'n'
      puts "Unexpected input: #{answer.inspect}, was expecting \"y\" or \"n\""
      get_bool prompt
    else
      answer == 'y'
    end
  end

  resource = "https://codepen.io/josh_cheek/pen/eLqGGJ"
  pens.each do |pen|
    driver.navigate.to pen                                 # go to the pen
    next unless get_bool("Add resource to this page?")
    driver.find_element(:css, '#settings-pane-css ').click # opens the css settings
    pre_resources  = driver.find_elements :css, '.external-resource-url-row'
    driver.find_element(:css, '#add-css-resource').click   # add a new row (makes sure there's an open spot for it)
    post_resources = driver.find_elements :css, '.external-resource-url-row'
    new_resources  = post_resources - pre_resources         # get the difference
    if new_resources.length != 1
      puts "uhm.... something went wrong, I was expecting to find a new css resource after I clicked the 'add another resource' button, but I found #{new_resources.length} instead!"
      exit
    end
    resource_input = new_resources.first.find_element :css, 'input'
    resource_input.send_keys resource

    driver.find_element(:css, '#item-settings-modal input.save-and-close').click
    driver.find_element(:css, '#run').click
  end
rescue StandardError
  require 'pry'
  binding.pry
end

require 'pry'
binding.pry

puts "----- All done! -----"
driver.quit
