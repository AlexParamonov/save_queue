def new_object
  new_class.new
end

def new_class
  klass = Class.new
  klass.send :include, SaveQueue::Object

  klass
end

def changed_object_for(klass)
  object = klass.new
  object.mark_as_changed
  object
end

def new_count_object
  target_class = new_class
  target_class.send :include, Count_mod
  target_class.new
end

module Count_mod
  def save_call_count
    @save_call_count.to_i
  end

  def save
    @save_call_count ||= 0
    @save_call_count += 1
  end
end

def object_that_return(value = nil, &block)
  Class.new do
    include SaveQueue::Object
    s = block_given? ? block : lambda { value }
    define_method :save, &s
  end.new
end