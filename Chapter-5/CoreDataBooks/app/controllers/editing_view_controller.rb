class EditingViewController < UIViewController
  attr_accessor :editedObject
  attr_accessor :editedFieldKey
  attr_accessor :editedFieldName

  attr_accessor :hasDeterminedWhetherEditingDate
  attr_accessor :editingDate

  def viewDidLoad
    super

    self.view.backgroundColor = UIColor.whiteColor

    self.title = self.editedFieldName

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

    # This long list of assignments will give us a UITextField that looks like
    # the example. Not to worry, with RubyMotion there are lots of ways to
    # get around verbose presentation code such as Motion Layout and Teacup.
    @textField = UITextField.alloc.initWithFrame([[20, 84], [280, 31]])
    @textField.borderStyle = UITextBorderStyleRoundedRect
    @textField.font = UIFont.systemFontOfSize(15)
    @textField.autocorrectionType = UITextAutocorrectionTypeNo
    @textField.keyboardType = UIKeyboardTypeDefault
    @textField.returnKeyType = UIReturnKeyDone
    @textField.clearButtonMode = UITextFieldViewModeWhileEditing
    @textField.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter

    self.view.addSubview @textField

    @datePicker = UIDatePicker.alloc.initWithFrame([[0, 64], [320, 216]])
    @datePicker.datePickerMode = UIDatePickerModeDate

    self.view.addSubview @datePicker
  end

  def viewWillAppear(animated)
    super

    if self.isEditingDate
      @textField.hidden = true
      @datePicker.hidden = false

      date = self.editedObject.valueForKey(self.editedFieldKey)

      if date.nil?
        date = NSDate.date
      end

      @datePicker.date = date
    else
      @textField.hidden = false
      @datePicker.hidden = true

      @textField.text = self.editedObject.send(self.editedFieldKey)
      @textField.placeholder = self.title
      @textField.becomeFirstResponder
    end
  end

  protected

  def save
    undoManager = cdq.contexts.current.undoManager

    undoManager.setActionName self.editedFieldName

    if self.editingDate
      self.editedObject.setValue(@datePicker.date,
                                 forKey:self.editedFieldKey)
    else
      self.editedObject.setValue(@textField.text,
                                 forKey:self.editedFieldKey)
    end

    self.navigationController.popViewControllerAnimated(true)
  end

  def cancel
    self.navigationController.popViewControllerAnimated(true)
  end

  def isEditingDate
    if self.hasDeterminedWhetherEditingDate
      return editingDate
    end

    entity = self.editedObject.entity
    attribute = entity.attributesByName[self.editedFieldKey]
    attributeClassName = attribute.attributeValueClassName

    if attributeClassName == "NSDate"
      self.editingDate = true
    else
      self.editingDate = false
    end

    self.hasDeterminedWhetherEditingDate = true

    return self.editingDate
  end
end
