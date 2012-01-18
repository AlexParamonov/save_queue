def fill_queue
  5.times do
    queue << new_element
  end
end

def new_element(name = :element, options = {})
  element = stub(name)
  element.stub(:save).and_return(options.has_key?(:saved) ? options[:saved] : true)
  element.stub(:has_unsaved_changes?).and_return(options.has_key?(:changed) ? options[:changed] : true)

  element
end

def new_velement(options = {:valid => true})
  object = new_element
  object.stub(:valid?).and_return(options[:valid])
  object
end
