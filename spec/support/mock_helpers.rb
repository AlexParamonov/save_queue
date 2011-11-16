#def new_mock_object name
#  bad_object = mock name
#  bad_object.stub_chain(:class, :include?).with(SaveQueue::Object).and_return(true)
#  bad_object.stub(:valid?).and_return(true)
#  bad_object.stub(:save).and_return(true)
#  bad_object.stub(:has_unsaved_changes?).and_return(true)
#
#  bad_object
#end
#
#def new_object
#  object = Tests::Object.new
#  object.stub(:valid?).and_return(true)
#  object.mark_as_changed
#
#  object
#end