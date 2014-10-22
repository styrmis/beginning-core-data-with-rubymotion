schema "0001 initial" do
  entity "Person" do
    string :name, optional: false
    string :address, optional: true
  end
end
