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