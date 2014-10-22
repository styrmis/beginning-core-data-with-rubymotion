schema "0003 migrate name data" do
  entity "Person" do
    string :name, optional: false

    string :first_name, optional: true
    string :last_name, optional: true

    string :address, optional: true
  end
end
