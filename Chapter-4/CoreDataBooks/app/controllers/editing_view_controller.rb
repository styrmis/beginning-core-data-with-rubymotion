class EditingViewController < UIViewController
  attr_accessor :editedObject
  attr_accessor :editedFieldKey
  attr_accessor :editedFieldName

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
  end
end
