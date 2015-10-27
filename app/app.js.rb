# use sprockets directive to include jquery
#= require 'jquery'

require 'opal'
require 'opal-jquery'

require_relative 'lib/chess'
include ChessHelper

Document.ready? do
  Game.new
end

class Game
  
  def initialize

    @ui_heading = Element['#heading']
    @ui_fen = Element['#fen']
    @ui_pgn = Element['#pgn']
    
    @position = Position.initial
    @pgn = ''
    create_board
    update_state

    @ui_board.on(:click, '.cell') do |evt|
      cell_click(evt)
    end

    Document.on(:click, '#new_game') do |evt|
      @position = Position.initial
      @pgn = ''
      update_state
    end

    Document.on(:click, '#load_fen') do |evt|
      current_fen = @position.inspect
      fen = `prompt('Import game position.\nEnter FEN string:', current_fen)`
      begin
        position = Position.fen(fen)
        puts 'FEN loaded'
        @position = position
        
        @pgn = ''
        update_state
      rescue => e
        puts e.message
        alert e.message
      end
    end

  end

  private

  def create_board
    @ui_board = Element.new.add_class('board')
    (0..7).each do |i|
      (0..7).each do |j|
        cell = Element.new.add_class('cell')
        cell.id = [j,i].to_idx

        notation = Element.new.add_class 'notation'
        notation.text = [j,i-1].to_idx.to_sq
        cell.append notation

        color = (i+j)%2 == 0 ? 'white' : 'black'
        cell.add_class(color)
        @ui_board.append cell
      end
    end

    @ui_heading.after @ui_board
    
    update_ui
  end


  def update_ui
    #update_board
    @position.board.each_with_index do |piece, index|
      @ui_board.find("##{index}").attr('data-piece', piece.to_s)
    end

    #heading
    turn_msg = @position.white ? 'White turn.' : 'Black turn.'
    check_msg = @position.in_check? ? 'Check! ' : ''
    @ui_heading.text = "#{check_msg} #{turn_msg}"
    
    #update_stats
    @ui_fen.value = @position.inspect
    @ui_pgn.text = @pgn
  end


  def cell_click(evt)

    @ui_board.children.remove_class 'selected'
    @ui_board.children.remove_class 'target'

    evt.current_target.add_class 'selected'

    @click_idxs.push  evt.current_target.id.to_i
    @click_idxs.shift

    from =  @click_idxs.last
    valid_moves =  @pm.select {|move| move.first == from}
    target_idxs = valid_moves.map{|m| m[1]}

    cell_ids = '#' + target_idxs.join(',#')
    Element[cell_ids].add_class 'target'

    if @pm.include?  @click_idxs
      move *@click_idxs

    elsif @pm.any? {|move| move.size > 2} && # possible moves has promotions [from,to,promote] 
          @pm.map{|move| move[0..1]}.include?(@click_idxs)
      move *@click_idxs, ask_promotion
    end
  end

  def move(*args)
    @pgn = @pgn +  @position.full_move.to_s + '. ' if @position.white
    @pgn = @pgn +  @position.move_to_san(*args) + ' '
    @position.move! *args
    update_state
    puts @position # to browser console
  end
  
  
  def update_state
    @pm = @position.possible_moves
    @click_idxs = [nil, nil]
    @ui_board.children.remove_class 'selected'

    update_ui

    game_over if @position.game_end?
  end

  def game_over
    game_status = case
                    when @position.checkmate? then 'Checkmate!'
                    when @position.stalemate? then 'Stalemate!'
                    when @position.draw?      then 'Draw!'
                  end

    @ui_heading.text = game_status
  end

  def ask_promotion
    # promote Pawn to Queen by default 
    @position.white ? :Q : :q
  end

end

