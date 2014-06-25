module SeriesCalc
  class Message
    attr_reader :creation_time
    attr_reader :verb
    attr_reader :type
    attr_reader :id
    attr_reader :content

    NULL_MESSAGE = Object.new.freeze

    def initialize(creation_time, verb, type, id, content)
      @creation_time = creation_time
      @verb = verb
      @type = type
      @id = id
      @content = content
    end
  end
end
