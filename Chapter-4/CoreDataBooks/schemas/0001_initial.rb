schema "0001 initial" do

  entity "Book" do
    string :title, optional: false
    string :author, optional: false
    datetime :copyright, optional: true
  end
end
