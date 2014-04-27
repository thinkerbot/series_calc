require 'series_calc/manager'

class Handler
  attr_reader :manager

  def initialize(manager)
    @manager = manager
  end

  def call(time, request_type, id, data)
    raise NotImplementedError
  end
end
