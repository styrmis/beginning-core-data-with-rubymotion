describe 'Book' do

  before do
    class << self
      include CDQ
    end
    cdq.setup
  end

  after do
    cdq.reset!
  end

  it 'should be a Book entity' do
    Book.entity_description.name.should == 'Book'
  end
end
