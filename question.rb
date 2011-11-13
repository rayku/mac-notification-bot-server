class Question
  attr_reader :body, :grade, :time_left

  def initialize args
    @body = args[:body]
    @grade = args[:grade]
    @time_left = args[:time_left]
    @link = args[:link]
  end

  def to_json(*a)
      {
        :body => @body,
        :grade => @grade,
        :timeLeft => @time_left,
        :link => @link
      }.to_json(*a)
  end
end
