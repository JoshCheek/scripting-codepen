require 'json'

class State
  def initialize(filename)
    self.filename    = filename
    self.pens_loaded = false
    self.pens        = {}
    if File.exist? filename
      load
    else
      save
    end
  end

  def resource
    @resource || ''
  end

  def resource=(resource)
    @resource = resource
    save
  end

  def pens_loaded?
    pens_loaded
  end

  def add_pens(hrefs)
    self.pens_loaded = true
    hrefs.each do |href|
      pens[href] ||= {
        evaluated: false,
        added:     false,
      }
    end
    save
  end

  def update_pen(href, evaluated:, added:)
    pen = pens.fetch(href)
    pen[:evaluated] = evaluated
    pen[:added]     = added
    save
  end

  def num_pens
    pens.size
  end

  def clear_pens
    self.pens_loaded = false
    self.pens = {}
    save
  end

  def each_pen
    return to_enum :each_pen unless block_given?
    pens.each.with_index(1) do |(href, state), index|
      yield index:     index,
            href:      href,
            evaluated: state.fetch(:evaluated),
            added:     state.fetch(:added)
    end
  end

  private

  attr_accessor :filename, :pens_loaded, :pens

  def save
    File.write filename, JSON.dump(
      resource:    resource,
      pens_loaded: pens_loaded,
      pens:        pens,
    )
    nil
  end

  def load
    json  = File.read filename
    state = JSON.parse json, symbolize_names: true
    self.resource    = state.fetch :resource
    self.pens_loaded = state.fetch :pens_loaded
    self.pens        = state.fetch :pens
  end

end
