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

    # This long list of assignments will give us a UITextField that looks like
    # the example. Not to worry, with RubyMotion there are lots of ways to
    # get around verbose presentation code such as Motion Layout and Teacup.
    @textField = UITextField.alloc.initWithFrame([[20, 84], [280, 31]])
    @textField.borderStyle = UITextBorderStyleRoundedRect
    @textField.font = UIFont.systemFontOfSize(15)
    @textField.placeholder = ""
    @textField.autocorrectionType = UITextAutocorrectionTypeNo
    @textField.keyboardType = UIKeyboardTypeDefault
    @textField.returnKeyType = UIReturnKeyDone
    @textField.clearButtonMode = UITextFieldViewModeWhileEditing
    @textField.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter

    @textField.text = self.editedObject.send(self.editedFieldKey)

    self.view.addSubview @textField

    @datePicker = UIDatePicker.alloc.initWithFrame([[0, 64], [320, 216]])
    @datePicker.datePickerMode = UIDatePickerModeDate

    self.view.addSubview @datePicker
  end

  def viewWillAppear(animated)
    if self.isEditingDate()
      @textField.hidden = true
      @datePicker.hidden = false
    else
      @textField.hidden = false
      @datePicker.hidden = true
    end
  end

  protected

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
