require 'trello'
require 'ostruct'

require 'byebug'

class ScrumBoard
  attr_reader :id

  class InvalidRequestError < StandardError; end
  class BoardNotFoundError < StandardError; end
  class ColumnNotFoundError < StandardError; end

  def initialize(id, dev_key, member_token, settings)
    @client   = Trello::Client.new(developer_public_key: dev_key,
                                   member_token: member_token)
    @settings = settings
    @id       = id
  end

  def cards(type = :all, *types)
    types.push(type).reduce([]) do |ar, t|
      ar << case t
            when :all then columns.flat_map(&:cards)
            when :done then done_column.committed_cards
            when :open then open_columns.flat_map(&:committed_cards)

            when :extra_done then done_column.extra_cards
            when :extra_open then open_columns.flat_map(&:extra_cards)

            when :unplanned_done then done_column.unplanned_cards
            when :unplanned_open then open_columns.flat_map(&:unplanned_open)

            when :fast_lane_done then done_column.fast_lane_cards
            when :fast_lane_open then open_columns.flat_map(&:fast_lane_cards)
            else []
            end
    end
  end

  def storypoints(type = :all, *types)
    cards(type, types).map(&:story_points).sum
  end

  def tasks(type = :all, *types)
    types.push(type).reduce([]) do |ar, t|
      ar << case t
            when :all then cards(:open, :done).map(&:tasks).sum
            when :closed then cards(:open, :done).map(&:done_tasks).sum

            when :extra_all then cards(:extra_open, :extra_done).map(&:tasks).sum
            when :extra_closed then cards(:extra_open, :extra_done).map(&:done_tasks).sum

            when :unplanned_all then cards(:unplanned_open, :unplanned_done).map(&:tasks).sum
            when :unplanned_closed then cards(:unplanned_open, :unplanned_done).map(&:done_tasks).sum
            else []
            end
    end
  end

  def meta_cards
    (open_columns.flat_map(&:fast_lane_cards) + done_column.cards).select(&:meta_card?)
  end

  def done_column
    done_columns = columns.select do |column|
      column.name =~ @settings.done_column_name_regex
    end

    fail ColumnNotFoundError, 'Done column not found' if done_columns.empty?

    @done_column ||= done_columns.first
  end

  def open_columns
    @open_columns ||= columns.select do |column|
      @settings.not_done_columns.include? column.name
    end
  end

  private

  def board_path
    "/boards/#{id}?lists=open&cards=open&card_checklists=all"
  end

  def board
    @board ||= JSON.parse @client.get(board_path), object_class: OpenStruct
  rescue JSON::JSONError => error
    raise InvalidRequestError, error.message
  rescue Trello::Error => error
    raise BoardNotFoundError, error.message
  end

  def columns
    @columns ||= board.lists.map do |column|
      cards = board.cards.select { |card| card.idList == column.id }
      Column.new(column, cards, @settings)
    end
  end
end
