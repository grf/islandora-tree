class IslandoraObjectNode

  attr_accessor :pid, :state, :content_models, :parents
  def initialize(pid, state=nil, *content_models)
    @pid = pid.sub(/^info:fedora\//, '')
    @state = state
    @content_models = content_models
    @properties = {}
    @parents = []
    @colors = []
  end

  def to_s
    "#{pid}/#{state} #{content_models.join(', ')} => #{parents.inspect}"
  end

  def add_content_model(value)
      @content_models.push value
  end

  def add_parent(parent)
    @parents.push(parent).uniq!
  end

  def color(val)
    @colors.push val
    @colors.uniq!
  end

  def colored?(val)
    return @colors.member? val
  end

  def uncolor(val)
    return @colors.delete_if { |elt| elt == val }
  end

end
