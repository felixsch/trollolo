require_relative 'spec_helper'

describe ScrumBoard do

  describe '#done_column' do
    let(:board_id)   { 'CRdddpdy' }
    let(:board_url) { "https://api.trello.com/1/boards/#{board_id}?card_checklists=all&cards=open&key=mykey&lists=open&token=mytoken" }
    let(:board_data) { load_test_file('full-board.json') }
    let(:settings)   { dummy_settings }

    before(:each) do
      stub_request(:get, board_url).to_return(status: 200, body: board_data)
    end

    let(:scrum_board) do
      ScrumBoard.new(board_id,
                     settings.developer_public_key,
                     settings.member_token,
                     settings)
    end

    it 'raises error when done column cannot be found' do
      
      settings.done_column_name_regex = /thiscolumndoesntexist/

      expect{scrum_board.done_column}.to raise_error ScrumBoard::ColumnNotFoundError
    end

    it 'finds done column with name "Done Sprint %s"' do

      columns = []

      column1 = double
      allow(column1).to receive(:name).and_return("Sprint Backlog")
      columns << column1

      column2 = double
      allow(column2).to receive(:name).and_return("Doing")
      columns << column2

      column3 = double
      allow(column3).to receive(:name).and_return("Done Sprint 43")
      columns << column3

      allow(scrum_board).to receive(:columns).and_return(columns)

      expect(scrum_board.done_column.name).to eq("Done Sprint 43")
    end

    it 'finds done column with name "Done Sprint %s" if there are multiple done columns' do

      columns = []

      column1 = double
      allow(column1).to receive(:name).and_return("Sprint Backlog")
      columns << column1

      column2 = double
      allow(column2).to receive(:name).and_return("Doing")
      columns << column2

      column3 = double
      allow(column3).to receive(:name).and_return("Done Sprint 44")
      columns << column3

      column4 = double
      allow(column4).to receive(:name).and_return("Done Sprint 43")
      columns << column4

      allow(scrum_board).to receive(:columns).and_return(columns)

      expect(scrum_board.done_column.name).to eq("Done Sprint 44")
    end

    it 'finds done column with name "Done (July 20th - August 3rd)"' do

      columns = []

      column1 = double
      allow(column1).to receive(:name).and_return("Sprint Backlog")
      columns << column1

      column2 = double
      allow(column2).to receive(:name).and_return("Doing")
      columns << column2

      column3 = double
      allow(column3).to receive(:name).and_return("Done (July 20th - August 3rd)")
      columns << column3

      allow(scrum_board).to receive(:columns).and_return(columns)

      expect(scrum_board.done_column.name).to eq("Done (July 20th - August 3rd)")
    end
  end
end
