require 'opal'
require 'opal-jquery'

require_relative 'lib/chess'

include ChessHelper


class Game
  attr_accessor :board
  
  def initialize
    @position = Position.initial
    @click_idxs = [nil,nil]
    
    
    # @pm = @position.possible_moves
    
    # p @position.possible_moves
    
    
    create_board
    show_board
    add_cells_click_events
    
  end
  
  private
  
  def create_board
    @board = Element.new.add_class('board')
    (0..7).each do |i|
      (0..7).each do |j|
        cell = Element.new.add_class('cell')
        cell.id = [j,i].to_idx

        notation = Element.new.add_class 'notation'
        notation.text = [j,i-1].to_idx.to_sq
        cell.append notation

        color = (i+j)%2 == 0 ? 'white' : 'black'
        cell.add_class(color)
        @board.append cell
      end
    end
  end
  
  def show_board
    @board.append_to_body
    update_board
  end
  
  def update_board
    @position.board.each_with_index do |piece, index|
      # Element["##{index}"].attr('data-piece', piece.to_s)
      @board.find("##{index}").attr('data-piece', piece.to_s)
    end
  end
  
  def add_cells_click_events
    @board.on(:click, '.cell') do |evt|
      @board.children.remove_class 'selected'
      evt.current_target.add_class 'selected'
      
      
      
    end
  end
  
end

Document.ready? do

  el = Element.find('#welcome')
  el.html('Chess with Opalrb')

  g = Game.new
  
  
  
end
