schema "0004 remove name field" do
  entity "Person" do
    string :first_name, optional: false
    string :last_name, optional: true

    string :address, optional: true
  end
end
