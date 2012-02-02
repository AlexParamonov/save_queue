def fill_queue
  5.times do
    queue << new_element
  end
end

def new_element(name = :element, options = {})
  element = stub(name)
  element.stub(:save).and_return(options.has_key?(:saved) ? options[:saved] : true)

  element
end

def new_velement(options = {:valid => true})
  object = new_element
  object.stub(:valid?).and_return(options[:valid])
  object
end

def new_queue_class(options = {})
  queue_class = Class.new
  queue_class.stub(:include?).with(Hooks).and_return(true)

  queue_class
end


ADD_METHODS = %w[add << push]