class AddViewController < DetailViewController
  attr_accessor :delegate
  attr_accessor :managedObjectContext

  def viewDidLoad
    super

    # Straight away we want the fields to be editable
    # without user interaction.
    self.setEditing(true, animated:false)

    # Add our Save and Cancel buttons
    @saveButton = UIBarButtonItem.alloc.initWithTitle("Save",
                                                      style:UIBarButtonItemStylePlain,
                                                      target:self,
                                                      action:'save')
    self.navigationItem.rightBarButtonItem = @saveButton

    @cancelButton = UIBarButtonItem.alloc.initWithTitle("Cancel",
                                                        style:UIBarButtonItemStylePlain,
                                                        target:self,
                                                        action:'cancel')
    self.navigationItem.leftBarButtonItem = @cancelButton
  end

  def cancel
    self.delegate.addViewController(self, didFinishWithSave:false)
  end

  def save
    self.delegate.addViewController(self, didFinishWithSave:true)
  end
end
