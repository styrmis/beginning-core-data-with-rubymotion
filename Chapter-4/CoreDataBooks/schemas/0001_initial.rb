schema "0001 initial" do

  entity "Book" do
    string :title, optional: false
    string :author, optional: false
    string :copyright, optional: true
  end
end
