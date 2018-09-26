class Browser
  attr_accessor :driver

  def initialize(driver)
    self.driver = driver
  end

  def visit(url)
    driver.navigate.to url
  end

  def click(selector)
    find(selector).click
    return true
  rescue Selenium::WebDriver::Error::NoSuchElementError
    return false
  rescue Selenium::WebDriver::Error::StaleElementReferenceError
    click selector
  end

  def find(selectors)
    selectors = [driver, selectors] if selectors.kind_of? String
    selectors.reduce do |element, selector|
      element.find_element :css, selector
    end
  end

  def all(selector, &mapper)
    elements = driver.find_elements(:css, selector)
    return elements unless mapper
    elements.map(&mapper)
  rescue Selenium::WebDriver::Error::StaleElementReferenceError
    all selector, &mapper
  end

  def type(text, into:)
    find(into).send_keys(text)
  end

  def quit
    driver.quit
  end
end

if $PROGRAM_NAME == __FILE__
  require "selenium-webdriver"
  require_relative 'browser'
  browser = Browser.new Selenium::WebDriver.for :chrome
  browser.visit 'http://google.com'
  browser.type 'hello', into: [browser.find('body'), 'input[type=text]']
  browser.type 'world', into: 'input[type=text]'
  browser.click 'a'
end
