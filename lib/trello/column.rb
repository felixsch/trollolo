#  Copyright (c) 2013-2015 SUSE LLC
#
#  This program is free software; you can redistribute it and/or
#  modify it under the terms of version 3 of the GNU General Public License as
#  published by the Free Software Foundation.
#
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.   See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with this program; if not, contact SUSE LLC.
#
#  To contact SUSE about this file by physical or electronic mail,
#  you may find current contact information at www.suse.com
class Column

  attr_reader :id
  attr_reader :cards

  def initialize(list, cards, settings)
    @settings  = settings
    @list_data = list
    @id        = list.id
    @cards     = cards.map {|card| Card.new(card, card.id) }
  end

  def name
    @list_data.name
  end

  def estimated_cards
    cards.select(&:estimated?)
  end

  def sum
    estimated_cards.map(&:story_points).sum
  end

  def tasks
    cards.map(&:tasks).sum
  end

  def done_tasks
    cards.map(&:done_tasks).sum
  end

  def extra_cards
    cards.select(&:extra?)
  end

  def unplanned_cards
    cards.select(&:unplanned?)
  end

  def committed_cards
    cards.select {|c| !c.extra? && !c.unplanned? }
  end

  def fast_lane_cards
    cards.select(&:fast_lane?)
  end

end
