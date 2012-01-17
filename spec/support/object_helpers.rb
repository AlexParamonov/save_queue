def new_object
  new_class.new
end

def new_class
  klass = Class.new
  klass.send :include, SaveQueue::Object

  klass
end