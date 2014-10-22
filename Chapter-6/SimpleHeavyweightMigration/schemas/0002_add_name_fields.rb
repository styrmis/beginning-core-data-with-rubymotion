schema "0002 add split name fields" do
  entity "Person" do
    string :name, optional: false

    # The new fields will be optional so that they
    # can be initially blank after the schema migration.
    # We will then populate them with data and remove
    # the original name attribute.
    string :first_name, optional: true
    string :last_name, optional: true

    string :address, optional: true
  end
end
